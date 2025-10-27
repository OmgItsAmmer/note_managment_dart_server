import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Auth Middleware Tests', () {
    const String baseUrl = 'http://localhost:8080';
    late HttpClient client;

    setUp(() {
      client = HttpClient();
    });

    tearDown(() {
      client.close();
    });

    test('Should allow health endpoint without authentication', () async {
      final request = await client.getUrl(Uri.parse('$baseUrl/health'));
      final response = await request.close();

      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      expect(body, 'ok');
    });

    test('Should allow requests with valid API key from server defaults',
        () async {
      final request = await client.getUrl(Uri.parse('$baseUrl/v1/notes'));
      request.headers.add('X-API-Key', 'test');
      final response = await request.close();

      // Server has default API keys including 'test'
      expect(response.statusCode, 200);
    });

    test('Should reject requests with invalid API key', () async {
      final request = await client.getUrl(Uri.parse('$baseUrl/v1/notes'));
      request.headers.add('X-API-Key', 'totally_invalid_key_xyz_123');
      final response = await request.close();

      // Should return 401 for invalid API key
      expect(response.statusCode, 401);
    });

    test('Should allow requests with valid API key', () async {
      final request = await client.getUrl(Uri.parse('$baseUrl/v1/notes'));
      request.headers.add('X-API-Key', 'test'); // Using default dev key
      final response = await request.close();

      expect(response.statusCode, 200);
    });
  });
}

// Note: Full auth testing with API keys requires setting environment variables
// at compile time or running integration tests with a real server instance.
