import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';

class NotesControllerDb {
  final AppDatabase _db;
  final _uuid = const Uuid();

  NotesControllerDb(this._db);

  Router get router {
    final r = Router();

    r.get('/', _list);
    r.post('/', _create);
    r.get('/<id>', _get);
    r.put('/<id>', _update);
    r.delete('/<id>', _delete);

    return r;
  }

  Future<Response> _list(Request req) async {
    try {
      final q = req.requestedUri.queryParameters;
      final page = int.tryParse(q['page'] ?? '1') ?? 1;
      final limit = int.tryParse(q['limit'] ?? '20') ?? 20;

      final items = await _db.getNotesPage(page, limit);
      final total = await _db.countNotes();

      return Response.ok(
          jsonEncode({
            'page': page,
            'limit': limit,
            'total': total,
            'items': items.map((n) => _toJson(n)).toList(),
          }),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _create(Request req) async {
    try {
      final body = jsonDecode(await req.readAsString()) as Map;
      final title = (body['title'] ?? '').toString().trim();
      final content = (body['content'] ?? '').toString();

      if (title.isEmpty || title.length > 120) {
        return Response(400,
            body: jsonEncode({'error': 'Invalid title'}),
            headers: {'content-type': 'application/json'});
      }
      if (content.length > 10000) {
        return Response(400,
            body: jsonEncode({'error': 'Content too long'}),
            headers: {'content-type': 'application/json'});
      }

      final id = _uuid.v4();
      final now = DateTime.now();

      final note = NotesCompanion(
        id: drift.Value(id),
        title: drift.Value(title),
        content: drift.Value(content.isEmpty ? null : content),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      );

      await _db.createNote(note);
      final created = await _db.getNoteById(id);

      if (created == null) {
        return Response.internalServerError(
            body: jsonEncode({'error': 'Failed to create note'}),
            headers: {'content-type': 'application/json'});
      }

      return Response(201,
          body: jsonEncode(_toJson(created)),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _get(Request req, String id) async {
    try {
      final note = await _db.getNoteById(id);
      if (note == null) {
        return Response(404,
            body: jsonEncode({'error': 'Not found'}),
            headers: {'content-type': 'application/json'});
      }
      return Response.ok(jsonEncode(_toJson(note)),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _update(Request req, String id) async {
    try {
      final note = await _db.getNoteById(id);
      if (note == null) {
        return Response(404,
            body: jsonEncode({'error': 'Not found'}),
            headers: {'content-type': 'application/json'});
      }

      final body = jsonDecode(await req.readAsString()) as Map;
      final title = (body['title'] ?? note.title).toString().trim();
      final content = (body['content'] ?? note.content ?? '').toString();

      if (title.isEmpty || title.length > 120) {
        return Response(400,
            body: jsonEncode({'error': 'Invalid title'}),
            headers: {'content-type': 'application/json'});
      }
      if (content.length > 10000) {
        return Response(400,
            body: jsonEncode({'error': 'Content too long'}),
            headers: {'content-type': 'application/json'});
      }

      final updated = note.copyWith(
        title: title,
        content: drift.Value(content.isEmpty ? null : content),
        updatedAt: DateTime.now(),
      );

      await _db.updateNote(updated);

      return Response.ok(jsonEncode(_toJson(updated)),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _delete(Request req, String id) async {
    try {
      final deleted = await _db.deleteNote(id);
      if (deleted == 0) {
        return Response(404,
            body: jsonEncode({'error': 'Not found'}),
            headers: {'content-type': 'application/json'});
      }
      return Response(204);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'content-type': 'application/json'});
    }
  }

  Map<String, dynamic> _toJson(Note n) => {
        'id': n.id,
        'title': n.title,
        'content': n.content,
        'createdAt': n.createdAt.toIso8601String(),
        'updatedAt': n.updatedAt.toIso8601String(),
      };
}
