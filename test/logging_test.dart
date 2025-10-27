import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:dart_backend_tech_test/src/middleware/logging.dart';

void main() {
  group('Logging Middleware Tests', () {
    test('Should log request and response details', () async {
      final handler =
          logRequestsCustom()((req) async => Response.ok('success'));
      final request = Request('GET', Uri.parse('http://localhost/v1/notes'));

      final response = await handler(request);

      expect(response.statusCode, 200);
    });

    test('Should handle exceptions and return 500', () async {
      final handler = logRequestsCustom()((req) async {
        throw Exception('Test error');
      });

      final request = Request('GET', Uri.parse('http://localhost/v1/notes'));
      final response = await handler(request);

      expect(response.statusCode, 500);
      expect(response.headers['content-type'], contains('application/json'));
      final body = await response.readAsString();
      expect(body, contains('error'));
    });

    test('Should pass through successful responses', () async {
      final handler = logRequestsCustom()((req) async {
        return Response.ok('test response');
      });

      final request = Request('POST', Uri.parse('http://localhost/v1/notes'));
      final response = await handler(request);

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'test response');
    });
  });
}
