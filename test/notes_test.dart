import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_backend_tech_test/src/controllers/notes_controller.dart';

void main() {
  test('Notes CRUD - Test all 3 operations', () async {
    final notes = NotesController();
    final app = Router()..mount('/v1/notes', notes.router);
    final server = await io.serve(app, 'localhost', 0);
    final port = server.port;

    // 1. CREATE a note
    final client = HttpClient();
    final createReq = await client.post('localhost', port, '/v1/notes');
    createReq.headers.contentType = ContentType.json;
    createReq.write(
        jsonEncode({'title': 'Test Note', 'content': 'This is a test note'}));
    final createRes = await createReq.close();
    expect(createRes.statusCode, 201);

    // Get the created note ID
    final createBody = await utf8.decodeStream(createRes);
    final createdNote = jsonDecode(createBody);
    final noteId = createdNote['id'];

    // 2. READ the note
    final readReq = await client.get('localhost', port, '/v1/notes/$noteId');
    final readRes = await readReq.close();
    expect(readRes.statusCode, 200);
    final readBody = await utf8.decodeStream(readRes);
    final readNote = jsonDecode(readBody);
    expect(readNote['title'], 'Test Note');

    // 3. UPDATE the note
    final updateReq = await client.put('localhost', port, '/v1/notes/$noteId');
    updateReq.headers.contentType = ContentType.json;
    updateReq.write(jsonEncode(
        {'title': 'Updated Note', 'content': 'This note has been updated'}));
    final updateRes = await updateReq.close();
    expect(updateRes.statusCode, 200);
    final updateBody = await utf8.decodeStream(updateRes);
    final updatedNote = jsonDecode(updateBody);
    expect(updatedNote['title'], 'Updated Note');

    // 4. LIST all notes (should have 1)
    final listReq = await client.get('localhost', port, '/v1/notes');
    final listRes = await listReq.close();
    expect(listRes.statusCode, 200);
    final listBody = await utf8.decodeStream(listRes);
    final listData = jsonDecode(listBody);
    expect(listData['total'], 1);

    // 5. DELETE the note
    final deleteReq =
        await client.delete('localhost', port, '/v1/notes/$noteId');
    final deleteRes = await deleteReq.close();
    expect(deleteRes.statusCode, 204);

    // 6. Verify note is deleted
    final verifyReq = await client.get('localhost', port, '/v1/notes/$noteId');
    final verifyRes = await verifyReq.close();
    expect(verifyRes.statusCode, 404);

    await server.close(force: true);
  });
}
