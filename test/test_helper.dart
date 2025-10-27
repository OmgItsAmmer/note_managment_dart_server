import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_backend_tech_test/src/middleware/auth.dart';
import 'package:dart_backend_tech_test/src/middleware/rate_limit.dart';
import 'package:dart_backend_tech_test/src/middleware/logging.dart';
import 'package:dart_backend_tech_test/src/controllers/notes_controller.dart';
import 'package:dart_backend_tech_test/src/services/feature_flags.dart';

// Test-specific auth middleware that allows any API key for testing
Middleware testAuthMiddleware() {
  return (Handler inner) {
    return (Request req) async {
      // Allow health without auth
      if (req.url.path == 'health') return inner(req);

      final key = req.headers['X-API-Key'];

      // In test mode, allow any API key (including null)
      // Attach key to context
      final ctx = {'apiKey': key};
      return inner(req.change(context: ctx));
    };
  };
}

class TestServer {
  late HttpServer _server;
  late int _port;
  late HttpClient _client;

  int get port => _port;
  HttpClient get client => _client;

  Future<void> start() async {
    // Clear rate limit buckets before starting
    clearRateLimitBuckets();

    final router = Router();

    // Healthcheck
    router.get('/health', (Request req) async {
      return Response.ok('ok', headers: {'content-type': 'text/plain'});
    });

    // Feature flags
    router.get('/v1/feature-flags', FeatureFlagsService.handleGet);

    // Notes CRUD
    final notes = NotesController();
    router.mount('/v1/notes', notes.router);

    // Pipeline
    final handler = const Pipeline()
        .addMiddleware(logRequestsCustom())
        .addMiddleware(testAuthMiddleware())
        .addMiddleware(rateLimitMiddleware())
        .addHandler(router);

    _server = await io.serve(handler, InternetAddress.loopbackIPv4, 0);
    _port = _server.port;
    _client = HttpClient();
  }

  Future<void> stop() async {
    _client.close();
    await _server.close(force: true);
    // Clear rate limit buckets after stopping
    clearRateLimitBuckets();
  }

  String get baseUrl => 'http://localhost:$_port';
}
