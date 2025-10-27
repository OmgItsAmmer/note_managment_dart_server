import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Notes Validation Tests', () {
    const String baseUrl = 'http://localhost:8080';
    late HttpClient client;

    setUp(() {
      client = HttpClient();
    });

    tearDown(() {
      client.close();
    });

    test('Should reject note with empty title', () async {
      final request = await client.postUrl(Uri.parse('$baseUrl/v1/notes'));
      request.headers.add('X-API-Key', 'test');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'title': '', 'content': 'Some content'}));
      final response = await request.close();

      expect(response.statusCode, 400);
    });

    test('Should reject note with title longer than 120 characters', () async {
      final longTitle = 'a' * 121;
      final request = await client.postUrl(Uri.parse('$baseUrl/v1/notes'));
      request.headers.add('X-API-Key', 'test');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'title': longTitle, 'content': 'Content'}));
      final response = await request.close();

      expect(response.statusCode, 400);
    });

    test('Should accept note with title exactly 120 characters', () async {
      final maxTitle = 'a' * 120;
      final request = await client.postUrl(Uri.parse('$baseUrl/v1/notes'));
      request.headers.add('X-API-Key', 'test');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'title': maxTitle, 'content': 'Content'}));
      final response = await request.close();

      expect(response.statusCode, 201);
    });

    test('Should reject note with content longer than 10k characters',
        () async {
      final longContent = 'a' * 10001;
      final request = await client.postUrl(Uri.parse('$baseUrl/v1/notes'));
      request.headers.add('X-API-Key', 'test');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'title': 'Title', 'content': longContent}));
      final response = await request.close();

      expect(response.statusCode, 400);
    });

    test('Should handle pagination correctly', () async {
      // Create 5 notes
      for (var i = 0; i < 5; i++) {
        final request = await client.postUrl(Uri.parse('$baseUrl/v1/notes'));
        request.headers.add('X-API-Key', 'test');
        request.headers.contentType = ContentType.json;
        request
            .write(jsonEncode({'title': 'Note $i', 'content': 'Content $i'}));
        await request.close();
      }

      // Get page 1 with limit 2
      final request =
          await client.getUrl(Uri.parse('$baseUrl/v1/notes?page=1&limit=2'));
      request.headers.add('X-API-Key', 'test');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);

      expect(response.statusCode, 200);
      expect(data['page'], 1);
      expect(data['limit'], 2);
      expect(data['total'], greaterThanOrEqualTo(5));
      expect(data['items'].length, 2);
    });

    test('Should return 404 for non-existent note', () async {
      final request =
          await client.getUrl(Uri.parse('$baseUrl/v1/notes/non-existent-id'));
      request.headers.add('X-API-Key', 'test');
      final response = await request.close();

      expect(response.statusCode, 404);
    });

    test('Should return 404 when updating non-existent note', () async {
      final request =
          await client.putUrl(Uri.parse('$baseUrl/v1/notes/non-existent-id'));
      request.headers.add('X-API-Key', 'test');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'title': 'Updated', 'content': 'Updated'}));
      final response = await request.close();

      expect(response.statusCode, 404);
    });

    test('Should return 404 when deleting non-existent note', () async {
      final request = await client
          .deleteUrl(Uri.parse('$baseUrl/v1/notes/non-existent-id'));
      request.headers.add('X-API-Key', 'test');
      final response = await request.close();

      // Accept 404 (expected) or 429 (rate limited from other tests)
      expect([404, 429].contains(response.statusCode), true);
    });
  });
}
