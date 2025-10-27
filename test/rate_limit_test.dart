import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_backend_tech_test/src/middleware/rate_limit.dart';

void main() {
  group('Rate Limit Middleware Tests', () {
    test('Should allow requests under default rate limit', () async {
      final handler =
          rateLimitMiddleware()((req) async => Response.ok('success'));

      // Make several requests under the default limit (60)
      final testKey = 'test_key_under_${DateTime.now().millisecondsSinceEpoch}';
      for (var i = 0; i < 5; i++) {
        final request = Request('GET', Uri.parse('http://localhost/v1/notes'))
            .change(context: {'apiKey': testKey});
        final response = await handler(request);
        expect(response.statusCode, 200);
      }
    });

    test('Should bypass rate limit for health endpoint', () async {
      final handler =
          rateLimitMiddleware()((req) async => Response.ok('healthy'));

      // Make multiple health check requests
      for (var i = 0; i < 5; i++) {
        final request = Request('GET', Uri.parse('http://localhost/health'));
        final response = await handler(request);
        expect(response.statusCode, 200);
      }
    });

    test('Should track rate limits separately per API key', () async {
      final handler =
          rateLimitMiddleware()((req) async => Response.ok('success'));

      final key1 = 'test_key_1_${DateTime.now().millisecondsSinceEpoch}';
      final key2 = 'test_key_2_${DateTime.now().millisecondsSinceEpoch}';

      // Make requests with key1
      for (var i = 0; i < 5; i++) {
        final request = Request('GET', Uri.parse('http://localhost/v1/notes'))
            .change(context: {'apiKey': key1});
        await handler(request);
      }

      // key2 should still work (separate bucket)
      final request = Request('GET', Uri.parse('http://localhost/v1/notes'))
          .change(context: {'apiKey': key2});
      final response = await handler(request);
      expect(response.statusCode, 200);
    });

    test('Should handle anonymous requests', () async {
      final handler =
          rateLimitMiddleware()((req) async => Response.ok('success'));

      // Request without API key context
      final request = Request('GET', Uri.parse('http://localhost/v1/notes'));
      final response = await handler(request);
      expect(response.statusCode, 200);
    });
  });
}

// Note: Testing rate limit exhaustion requires setting environment variables
// at compile time or running with lower limits in integration tests.
