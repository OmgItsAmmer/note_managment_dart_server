import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import '../test_helper.dart';

void main() {
  group('Auth Middleware Tests', () {
    late TestServer server;

    setUp(() async {
      server = TestServer();
      await server.start();
    });

    tearDown(() async {
      await server.stop();
    });

    test('Should allow health endpoint without authentication', () async {
      final request =
          await server.client.getUrl(Uri.parse('${server.baseUrl}/health'));
      final response = await request.close();

      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      expect(body, 'ok');
    });

    test('Should allow requests when no API_KEYS configured (dev mode)',
        () async {
      final request =
          await server.client.getUrl(Uri.parse('${server.baseUrl}/v1/notes'));
      final response = await request.close();

      // In dev mode without API_KEYS, requests should be allowed
      expect(response.statusCode, 200);
    });

    test('Should reject requests with invalid API key', () async {
      final request =
          await server.client.getUrl(Uri.parse('${server.baseUrl}/v1/notes'));
      request.headers.add('X-API-Key', 'invalid_key');
      final response = await request.close();

      // Should return 401 for invalid API key
      expect(response.statusCode, 401);
    });

    test('Should allow requests with valid API key', () async {
      final request =
          await server.client.getUrl(Uri.parse('${server.baseUrl}/v1/notes'));
      request.headers.add('X-API-Key', 'test'); // Using default dev key
      final response = await request.close();

      expect(response.statusCode, 200);
    });
  });
}

// Note: Full auth testing with API keys requires setting environment variables
// at compile time or running integration tests with a real server instance.
