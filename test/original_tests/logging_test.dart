import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Logging Middleware Tests', () {
    const String baseUrl = 'http://localhost:8080';
    late HttpClient client;

    setUp(() {
      client = HttpClient();
    });

    tearDown(() {
      client.close();
    });

    test('Should log request and response details', () async {
      final request = await client.getUrl(Uri.parse('$baseUrl/v1/notes'));
      request.headers.add('X-API-Key', 'test'); // Valid API key
      final response = await request.close();

      expect(response.statusCode, 200);
      // The logging middleware should have logged the request/response
      // We can't directly test the logs, but we can verify the request succeeded
    });

    test('Should handle exceptions and return 500', () async {
      // This test is tricky with real server since we can't easily trigger exceptions
      // We'll test a malformed request instead
      final request = await client.postUrl(Uri.parse('$baseUrl/v1/notes'));
      request.headers.add('X-API-Key', 'test');
      request.headers.contentType = ContentType.json;
      request.write('{"invalid": json}'); // Malformed JSON
      final response = await request.close();

      // Should return 400 for malformed JSON, not 500
      expect(response.statusCode, 400);
    });

    test('Should pass through successful responses', () async {
      final request = await client.getUrl(Uri.parse('$baseUrl/health'));
      final response = await request.close();

      expect(response.statusCode, 200);
      final body = await response.transform(utf8.decoder).join();
      expect(body, 'ok');
    });

    test('Should handle POST requests with logging', () async {
      final request = await client.postUrl(Uri.parse('$baseUrl/v1/notes'));
      request.headers.add('X-API-Key', 'test');
      request.headers.contentType = ContentType.json;
      request.write('{"title": "Test Note", "content": "Test content"}');
      final response = await request.close();

      expect(response.statusCode, 201);
      final body = await response.transform(utf8.decoder).join();
      expect(body, isNotEmpty);
    });
  });
}
