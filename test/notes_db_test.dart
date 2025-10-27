import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:drift/native.dart';
import 'package:dart_backend_tech_test/src/controllers/notes_controller_db.dart';
import 'package:dart_backend_tech_test/src/database/database.dart';

void main() {
  group('Notes CRUD with Database Persistence', () {
    late AppDatabase db;
    late NotesControllerDb controller;
    late HttpServer server;
    late int port;
    late HttpClient client;

    setUp(() async {
      // Use in-memory database for tests
      db = AppDatabase.forTesting(NativeDatabase.memory());
      controller = NotesControllerDb(db);
      final app = Router()..mount('/v1/notes', controller.router);
      server = await io.serve(app, 'localhost', 0);
      port = server.port;
      client = HttpClient();
    });

    tearDown(() async {
      await server.close(force: true);
      client.close();
    });

    test('Should create and retrieve a note from database', () async {
      // Create
      final createReq = await client.post('localhost', port, '/v1/notes');
      createReq.headers.contentType = ContentType.json;
      createReq.write(jsonEncode(
          {'title': 'Database Test', 'content': 'Persisted content'}));
      final createRes = await createReq.close();
      expect(createRes.statusCode, 201);

      final createBody = await utf8.decodeStream(createRes);
      final createdNote = jsonDecode(createBody) as Map;
      final noteId = createdNote['id'];

      // Verify it exists in database
      final dbNote = await db.getNoteById(noteId as String);
      expect(dbNote, isNot(null));
      expect(dbNote!.title, 'Database Test');
      expect(dbNote.content, 'Persisted content');
    });

    test('Should update note in database', () async {
      // Create
      final createReq = await client.post('localhost', port, '/v1/notes');
      createReq.headers.contentType = ContentType.json;
      createReq.write(
          jsonEncode({'title': 'Original', 'content': 'Original content'}));
      final createRes = await createReq.close();
      final createBody = await utf8.decodeStream(createRes);
      final createdNote = jsonDecode(createBody) as Map;
      final noteId = createdNote['id'] as String;

      // Update
      final updateReq =
          await client.put('localhost', port, '/v1/notes/$noteId');
      updateReq.headers.contentType = ContentType.json;
      updateReq.write(
          jsonEncode({'title': 'Updated', 'content': 'Updated content'}));
      final updateRes = await updateReq.close();
      expect(updateRes.statusCode, 200);

      // Verify in database
      final dbNote = await db.getNoteById(noteId);
      expect(dbNote!.title, 'Updated');
      expect(dbNote.content, 'Updated content');
    });

    test('Should delete note from database', () async {
      // Create
      final createReq = await client.post('localhost', port, '/v1/notes');
      createReq.headers.contentType = ContentType.json;
      createReq
          .write(jsonEncode({'title': 'To Delete', 'content': 'Delete me'}));
      final createRes = await createReq.close();
      final createBody = await utf8.decodeStream(createRes);
      final createdNote = jsonDecode(createBody) as Map;
      final noteId = createdNote['id'] as String;

      // Verify exists
      var dbNote = await db.getNoteById(noteId);
      expect(dbNote, isNot(null));

      // Delete
      final deleteReq =
          await client.delete('localhost', port, '/v1/notes/$noteId');
      final deleteRes = await deleteReq.close();
      expect(deleteRes.statusCode, 204);

      // Verify deleted
      dbNote = await db.getNoteById(noteId);
      expect(dbNote, isNull);
    });

    test('Should support pagination with database', () async {
      // Create 5 notes
      for (var i = 0; i < 5; i++) {
        final req = await client.post('localhost', port, '/v1/notes');
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({'title': 'Note $i', 'content': 'Content $i'}));
        await req.close();
      }

      // Get first page
      final listReq =
          await client.get('localhost', port, '/v1/notes?page=1&limit=2');
      final listRes = await listReq.close();
      expect(listRes.statusCode, 200);

      final listBody = await utf8.decodeStream(listRes);
      final listData = jsonDecode(listBody) as Map;

      expect(listData['page'], 1);
      expect(listData['limit'], 2);
      expect(listData['total'], 5);
      expect((listData['items'] as List).length, 2);
    });

    test('Should validate title length in database', () async {
      final longTitle = 'a' * 121;
      final req = await client.post('localhost', port, '/v1/notes');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'title': longTitle, 'content': 'Content'}));
      final res = await req.close();

      expect(res.statusCode, 400);
    });
  });
}
