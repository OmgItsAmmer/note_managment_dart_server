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

    test('Should reject requests without API key', () async {
      final handler = authMiddleware()((req) async => Response.ok('success'));

      final request = Request('GET', Uri.parse('http://localhost/v1/notes'));

      final response = await handler(request);
      expect(response.statusCode, 401);
    });

    test('Should allow requests with valid API key', () async {
      final handler = authMiddleware()((req) async => Response.ok('success'));

      final request = Request('GET', Uri.parse('http://localhost/v1/notes'),
          headers: {'X-API-Key': 'test'});

      final response = await handler(request);
      expect(response.statusCode, 200);
    });

    test('Should process requests and pass API key in context', () async {
      var handlerCalled = false;
      String? capturedKey;
      final handler = authMiddleware()((req) async {
        handlerCalled = true;
        capturedKey = req.context['apiKey'] as String?;
        return Response.ok('success');
      });

      final request = Request('GET', Uri.parse('http://localhost/v1/notes'),
          headers: {'X-API-Key': 'standard'});
      await handler(request);

      expect(handlerCalled, true);
      expect(capturedKey, 'standard');
    });
  });
}

// Note: Full auth testing with API keys requires setting environment variables
// at compile time or running integration tests with a real server instance.
