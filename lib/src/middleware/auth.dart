import 'dart:io';
import 'package:shelf/shelf.dart';

// Reads X-API-Key header and validates against env API_KEYS (colon-separated).
Middleware authMiddleware() {
  return (Handler inner) {
    return (Request req) async {
      // Allow health, OpenAPI spec, and Swagger UI without auth
      if (req.url.path == 'health' || 
          req.url.path == 'openapi.yaml' || 
          req.url.path.startsWith('docs')) {
        return inner(req);
      }

      final key = req.headers['X-API-Key'];

      // Use runtime environment variable from Platform.environment
      final apiKeysEnv = Platform.environment['API_KEYS'] ??
          'test:standard:enhanced:enterprise'; // Default keys
      final envKeys =
          apiKeysEnv.isEmpty ? <String>{} : apiKeysEnv.split(':').toSet();

      if (envKeys.isEmpty) {
        // Allow if not configured (for local dev); candidates can change if desired.
        return inner(req);
      }
      if (key == null || !envKeys.contains(key)) {
        return Response(401, body: 'Unauthorized: missing or invalid API key');
      }
      // Attach key to context
      final ctx = {'apiKey': key};
      return inner(req.change(context: ctx));
    };
  };
}
