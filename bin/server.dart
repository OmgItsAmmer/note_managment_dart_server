// dart run bin/server.dart
// dart test test/original_tests/
// dart test test/original_tests/

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:dart_backend_tech_test/src/middleware/auth.dart';
import 'package:dart_backend_tech_test/src/middleware/rate_limit.dart';
import 'package:dart_backend_tech_test/src/middleware/logging.dart';
import 'package:dart_backend_tech_test/src/controllers/notes_controller.dart';
import 'package:dart_backend_tech_test/src/controllers/notes_controller_db.dart';
import 'package:dart_backend_tech_test/src/database/database.dart';
import 'package:dart_backend_tech_test/src/services/feature_flags.dart';

void main(List<String> args) async {
  // Set up dummy environment variables for development
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final apiKeys =
      Platform.environment['API_KEYS'] ?? 'test:standard:enhanced:enterprise';
  final rateLimitMax = Platform.environment['RATE_LIMIT_MAX'] ?? '100';
  final rateLimitWindow = Platform.environment['RATE_LIMIT_WINDOW_SEC'] ?? '60';
  final usePersistence = Platform.environment['USE_PERSISTENCE'] == 'true';

  final router = Router();

  // Healthcheck
  router.get('/health', (Request req) async {
    return Response.ok('ok', headers: {'content-type': 'text/plain'});
  });

  // OpenAPI spec
  router.get('/openapi.yaml', (Request req) async {
    final file = File('openapi.yaml');
    if (await file.exists()) {
      final contents = await file.readAsString();
      return Response.ok(contents,
          headers: {'content-type': 'application/x-yaml'});
    }
    return Response.notFound('OpenAPI spec not found');
  });

  // Swagger UI
  final staticHandler =
      createStaticHandler('public', defaultDocument: 'index.html');
  router.mount('/docs/', staticHandler);

  // Feature flags
  router.get('/v1/feature-flags', FeatureFlagsService.handleGet);

  // Notes CRUD - Choose between in-memory or database persistence
  if (usePersistence) {
    print('📊 Using SQLite database persistence');
    final db = AppDatabase();
    final notes = NotesControllerDb(db);
    router.mount('/v1/notes', notes.router);
  } else {
    print('💾 Using in-memory storage (set USE_PERSISTENCE=true for database)');
    final notes = NotesController();
    router.mount('/v1/notes', notes.router);
  }

  // Pipeline
  final handler = const Pipeline()
      .addMiddleware(logRequestsCustom())
      .addMiddleware(authMiddleware())
      .addMiddleware(rateLimitMiddleware())
      .addHandler(router);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('🚀 Server listening on port ${server.port}');
  print('📋 Available API Keys: $apiKeys');
  print('🔧 Rate Limit: $rateLimitMax requests per $rateLimitWindow seconds');
  print('🌐 Health check: http://localhost:${server.port}/health');
  print('📝 Notes API: http://localhost:${server.port}/v1/notes');
  print('🚩 Feature flags: http://localhost:${server.port}/v1/feature-flags');
  print(
      '📚 API Documentation (Swagger UI): http://localhost:${server.port}/docs');
}
