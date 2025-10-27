import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Notes CRUD Tests', () {
    const String baseUrl = 'http://localhost:8080';
    late HttpClient client;

    setUp(() {
      client = HttpClient();
    });

    tearDown(() {
      client.close();
    });

    test('Notes CRUD - Test all operations', () async {
      // 1. CREATE a note
      final createRequest =
          await client.postUrl(Uri.parse('$baseUrl/v1/notes'));
      createRequest.headers.add('X-API-Key', 'test');
      createRequest.headers.contentType = ContentType.json;
      createRequest.write(
          jsonEncode({'title': 'Test Note', 'content': 'This is a test note'}));
      final createResponse = await createRequest.close();
      expect(createResponse.statusCode, 201);

      // Get the created note ID
      final createBody = await createResponse.transform(utf8.decoder).join();
      final createdNote = jsonDecode(createBody);
      final noteId = createdNote['id'];

      // 2. READ the note
      final readRequest =
          await client.getUrl(Uri.parse('$baseUrl/v1/notes/$noteId'));
      readRequest.headers.add('X-API-Key', 'test');
      final readResponse = await readRequest.close();
      expect(readResponse.statusCode, 200);
      final readBody = await readResponse.transform(utf8.decoder).join();
      final readNote = jsonDecode(readBody);
      expect(readNote['title'], 'Test Note');

      // 3. UPDATE the note
      final updateRequest =
          await client.putUrl(Uri.parse('$baseUrl/v1/notes/$noteId'));
      updateRequest.headers.add('X-API-Key', 'test');
      updateRequest.headers.contentType = ContentType.json;
      updateRequest.write(jsonEncode(
          {'title': 'Updated Note', 'content': 'This note has been updated'}));
      final updateResponse = await updateRequest.close();
      expect(updateResponse.statusCode, 200);
      final updateBody = await updateResponse.transform(utf8.decoder).join();
      final updatedNote = jsonDecode(updateBody);
      expect(updatedNote['title'], 'Updated Note');

      // 4. LIST all notes (should have at least 1)
      final listRequest = await client.getUrl(Uri.parse('$baseUrl/v1/notes'));
      listRequest.headers.add('X-API-Key', 'test');
      final listResponse = await listRequest.close();
      expect(listResponse.statusCode, 200);
      final listBody = await listResponse.transform(utf8.decoder).join();
      final listData = jsonDecode(listBody);
      expect(listData['total'], greaterThanOrEqualTo(1));

      // 5. DELETE the note
      final deleteRequest =
          await client.deleteUrl(Uri.parse('$baseUrl/v1/notes/$noteId'));
      deleteRequest.headers.add('X-API-Key', 'test');
      final deleteResponse = await deleteRequest.close();
      expect(deleteResponse.statusCode, 204);

      // 6. Verify note is deleted
      final verifyRequest =
          await client.getUrl(Uri.parse('$baseUrl/v1/notes/$noteId'));
      verifyRequest.headers.add('X-API-Key', 'test');
      final verifyResponse = await verifyRequest.close();
      expect(verifyResponse.statusCode, 404);
    });
  });
}
