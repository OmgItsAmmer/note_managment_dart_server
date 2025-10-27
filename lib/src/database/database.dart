import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Define the notes table
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get content => text().withLength(min: 0, max: 10000).nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // For testing, allow custom executor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
      );

  // CRUD operations for Notes
  Future<List<Note>> getAllNotes() => select(notes).get();

  Future<Note?> getNoteById(String id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> createNote(NotesCompanion note) => into(notes).insert(note);

  Future<bool> updateNote(Note note) => update(notes).replace(note);

  Future<int> deleteNote(String id) =>
      (delete(notes)..where((t) => t.id.equals(id))).go();

  // Paginated list
  Future<List<Note>> getNotesPage(int page, int limit) {
    final offset = (page - 1) * limit;
    return (select(notes)..limit(limit, offset: offset)).get();
  }

  Future<int> countNotes() async {
    final query = selectOnly(notes)..addColumns([notes.id.count()]);
    final result = await query.getSingle();
    return result.read(notes.id.count()) ?? 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // For server applications, use a local file database
    final dbFolder = Directory.current.path;
    final file = File(p.join(dbFolder, 'notes.db'));
    return NativeDatabase.createInBackground(file);
  });
}
