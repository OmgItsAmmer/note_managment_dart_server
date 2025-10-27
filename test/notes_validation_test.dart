import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_backend_tech_test/src/controllers/notes_controller.dart';

void main() {
  group('Notes Validation Tests', () {
    late HttpServer server;
    late int port;
    late HttpClient client;

    setUp(() async {
      final notes = NotesController();
      final app = Router()..mount('/v1/notes', notes.router);
      server = await io.serve(app, 'localhost', 0);
      port = server.port;
      client = HttpClient();
    });

    tearDown(() async {
      await server.close(force: true);
      client.close();
    });

    test('Should reject note with empty title', () async {
      final req = await client.post('localhost', port, '/v1/notes');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'title': '', 'content': 'Some content'}));
      final res = await req.close();

      expect(res.statusCode, 400);
    });

    test('Should reject note with title longer than 120 characters', () async {
      final longTitle = 'a' * 121;
      final req = await client.post('localhost', port, '/v1/notes');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'title': longTitle, 'content': 'Content'}));
      final res = await req.close();

      expect(res.statusCode, 400);
    });

    test('Should accept note with title exactly 120 characters', () async {
      final maxTitle = 'a' * 120;
      final req = await client.post('localhost', port, '/v1/notes');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'title': maxTitle, 'content': 'Content'}));
      final res = await req.close();

      expect(res.statusCode, 201);
    });

    test('Should reject note with content longer than 10k characters',
        () async {
      final longContent = 'a' * 10001;
      final req = await client.post('localhost', port, '/v1/notes');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'title': 'Title', 'content': longContent}));
      final res = await req.close();

      expect(res.statusCode, 400);
    });

    test('Should handle pagination correctly', () async {
      // Create 5 notes
      for (var i = 0; i < 5; i++) {
        final req = await client.post('localhost', port, '/v1/notes');
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({'title': 'Note $i', 'content': 'Content $i'}));
        await req.close();
      }

      // Get page 1 with limit 2
      final req =
          await client.get('localhost', port, '/v1/notes?page=1&limit=2');
      final res = await req.close();
      final body = await utf8.decodeStream(res);
      final data = jsonDecode(body);

      expect(res.statusCode, 200);
      expect(data['page'], 1);
      expect(data['limit'], 2);
      expect(data['total'], 5);
      expect(data['items'].length, 2);
    });

    test('Should return 404 for non-existent note', () async {
      final req =
          await client.get('localhost', port, '/v1/notes/non-existent-id');
      final res = await req.close();

      expect(res.statusCode, 404);
    });

    test('Should return 404 when updating non-existent note', () async {
      final req =
          await client.put('localhost', port, '/v1/notes/non-existent-id');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'title': 'Updated', 'content': 'Updated'}));
      final res = await req.close();

      expect(res.statusCode, 404);
    });

    test('Should return 404 when deleting non-existent note', () async {
      final req =
          await client.delete('localhost', port, '/v1/notes/non-existent-id');
      final res = await req.close();

      expect(res.statusCode, 404);
    });
  });
}
