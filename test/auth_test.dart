import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_backend_tech_test/src/middleware/auth.dart';

void main() {
  group('Auth Middleware Tests', () {
    test('Should allow health endpoint without authentication', () async {
      final handler = authMiddleware()((req) async => Response.ok('healthy'));

      final request = Request('GET', Uri.parse('http://localhost/health'));

      final response = await handler(request);
      expect(response.statusCode, 200);
    });

    test('Should allow requests when no API_KEYS configured (dev mode)',
        () async {
      // When API_KEYS is not configured, auth middleware allows all requests
      final handler = authMiddleware()((req) async => Response.ok('success'));

      final request = Request('GET', Uri.parse('http://localhost/v1/notes'));

      final response = await handler(request);
      expect(response.statusCode, 200);
    });
      
    test('Should process requests and allow inner handler to run', () async {
      var handlerCalled = false;
      final handler = authMiddleware()((req) async {
        handlerCalled = true;
        return Response.ok('success');
      });

      final request = Request('GET', Uri.parse('http://localhost/v1/notes'));
      await handler(request);

      expect(handlerCalled, true);
    });
  });
}

// Note: Full auth testing with API keys requires setting environment variables
// at compile time or running integration tests with a real server instance.
