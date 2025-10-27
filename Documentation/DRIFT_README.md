# Drift SQLite Persistence Documentation

## Overview

This project implements **persistence with SQLite via Drift**, a modern Dart ORM
that provides type-safe database operations. Drift generates code at compile
time, ensuring type safety and reducing runtime errors.

## ✅ **Working PowerShell Commands**

Here are the **tested and working** PowerShell commands for testing Drift
persistence:

### **1. Start Server with Persistence**

```powershell
$env:USE_PERSISTENCE="true"; dart run bin/server.dart
```

### **2. Health Check**

```powershell
curl.exe "http://localhost:8080/health"
```

### **3. Create Note (JSON File Method)**

```powershell
# Create JSON file
echo '{"title":"PowerShell Test","content":"Testing Drift persistence!"}' > test-note.json

# Send POST request
curl.exe -X POST "http://localhost:8080/v1/notes" `
  -H "X-API-Key: test" `
  -H "Content-Type: application/json" `
  -d "@test-note.json"
```

### **4. List Notes**

```powershell
curl.exe "http://localhost:8080/v1/notes" -H "X-API-Key: test"
```

### **5. Test Persistence**

```powershell
# Stop server (Ctrl+C), then restart
$env:USE_PERSISTENCE="true"; dart run bin/server.dart

# Check if notes survived restart
curl.exe "http://localhost:8080/v1/notes" -H "X-API-Key: test"
```

**Expected Results:**

- ✅ Server starts with "📊 Using SQLite database persistence"
- ✅ Health check returns "ok"
- ✅ POST creates note with UUID and timestamps
- ✅ GET returns paginated list with created notes
- ✅ Notes persist after server restart (data survives!)

---

## How It Works

### 1. **Drift Architecture**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Dart Code     │───▶│  Drift Compiler  │───▶│  Generated Code │
│ (database.dart) │    │ (build_runner)   │    │ (database.g.dart)│
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   SQLite File    │
                       │   (notes.db)     │
                       └──────────────────┘
```

### 2. **Key Components**

#### **Table Definition** (`lib/src/database/database.dart`)

```dart
class Notes extends Table {
  TextColumn get id => text()();                    // UUID primary key
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get content => text().withLength(min: 0, max: 10000).nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### **Database Class**

```dart
@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // Testing constructor
  AppDatabase.forTesting(QueryExecutor e) : super(e);
  
  @override
  int get schemaVersion => 1;
  
  // CRUD operations
  Future<List<Note>> getAllNotes() => select(notes).get();
  Future<Note?> getNoteById(String id) => /* ... */;
  Future<int> createNote(NotesCompanion note) => into(notes).insert(note);
  // ... more methods
}
```

#### **Generated Code** (`database.g.dart`)

- Contains `_$AppDatabase` base class
- Provides type-safe query methods
- Handles SQLite connection management
- Includes data classes (`Note`, `NotesCompanion`)

### 3. **Dual-Mode Operation**

The server supports both storage modes:

```dart
// In bin/server.dart
if (usePersistence) {
  print('📊 Using SQLite database persistence');
  final db = AppDatabase();                    // SQLite via Drift
  final notes = NotesControllerDb(db);
} else {
  print('💾 Using in-memory storage');
  final notes = NotesController();            // In-memory Map
}
```

**Environment Variable**: `USE_PERSISTENCE=true/false`

## Testing the Feature

### 1. **Unit Tests** (Automated)

Run the dedicated database tests:

```bash
dart test test/notes_db_test.dart
```

**Test Coverage:**

- ✅ Create note in database
- ✅ Retrieve note from database
- ✅ Update note in database
- ✅ Delete note from database
- ✅ Pagination with database
- ✅ Input validation with database

### 2. **Manual Testing** (Interactive)

#### **Step 1: Start Server with Persistence**

**For PowerShell (Windows):**

```powershell
# Enable SQLite persistence
$env:USE_PERSISTENCE="true"; dart run bin/server.dart
```

**For Bash/Linux/Mac:**

```bash
# Enable SQLite persistence
USE_PERSISTENCE=true dart run bin/server.dart
```

You should see:

```
📊 Using SQLite database persistence
🚀 Server listening on port 8080
```

#### **Step 2: Create a Note**

**For PowerShell (Windows):**

```powershell
# Method 1: Using JSON file (recommended)
echo '{"title":"My First Note","content":"This is persisted to SQLite!"}' > note.json
curl.exe -X POST "http://localhost:8080/v1/notes" `
  -H "X-API-Key: test" `
  -H "Content-Type: application/json" `
  -d "@note.json"

# Method 2: Inline JSON (may have quote issues)
curl.exe -X POST "http://localhost:8080/v1/notes" `
  -H "X-API-Key: test" `
  -H "Content-Type: application/json" `
  -d '{\"title\":\"My First Note\",\"content\":\"This is persisted to SQLite!\"}'
```

**For Bash/Linux/Mac:**

```bash
curl -X POST http://localhost:8080/v1/notes \
  -H "X-API-Key: test" \
  -H "Content-Type: application/json" \
  -d '{"title": "My First Note", "content": "This is persisted to SQLite!"}'
```

**Expected Response:**

```json
{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "My First Note",
    "content": "This is persisted to SQLite!",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "updatedAt": "2024-01-15T10:30:00.000Z"
}
```

#### **Step 3: Verify Persistence**

```bash
# Restart the server
# Stop: Ctrl+C
# Start again:
USE_PERSISTENCE=true dart run bin/server.dart

# List notes - your note should still be there!
```

**For PowerShell (Windows):**

```powershell
curl.exe "http://localhost:8080/v1/notes" -H "X-API-Key: test"
```

**For Bash/Linux/Mac:**

```bash
curl http://localhost:8080/v1/notes -H "X-API-Key: test"
```

**Expected Response:**

```json
{
    "page": 1,
    "limit": 20,
    "total": 1,
    "items": [
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "title": "My First Note",
            "content": "This is persisted to SQLite!",
            "createdAt": "2024-01-15T10:30:00.000Z",
            "updatedAt": "2024-01-15T10:30:00.000Z"
        }
    ]
}
```

#### **Step 4: Compare with In-Memory Mode**

```bash
# Stop server, restart without persistence
dart run bin/server.dart

# List notes - should be empty (data lost)
```

**For PowerShell (Windows):**

```powershell
curl.exe "http://localhost:8080/v1/notes" -H "X-API-Key: test"
```

**For Bash/Linux/Mac:**

```bash
curl http://localhost:8080/v1/notes -H "X-API-Key: test"
```

**Expected Response:**

```json
{
    "page": 1,
    "limit": 20,
    "total": 0,
    "items": []
}
```

### 3. **Database File Inspection**

The SQLite database is created as `notes.db` in the project root:

```bash
# Check if database file exists
ls -la notes.db

# Inspect database contents (if sqlite3 is installed)
sqlite3 notes.db ".tables"
sqlite3 notes.db "SELECT * FROM notes;"
```

### 4. **Performance Testing**

Run the performance test to see database impact:

```bash
dart test test/performance_test.dart
```

**Expected Results:**

- In-memory: ~3ms average latency
- SQLite: ~4-5ms average latency (slight overhead)

### 5. **Docker Testing**

Test with Docker container:

```bash
# Build image
docker build -t dart-tech-test:latest .

# Run with persistence
docker run -p 8080:8080 \
  -e USE_PERSISTENCE=true \
  -e API_KEYS="test:standard:enhanced:enterprise" \
  dart-tech-test:latest

# Test API
curl http://localhost:8080/health
```

**For PowerShell (Windows):**

```powershell
curl.exe "http://localhost:8080/health"
curl.exe -X POST "http://localhost:8080/v1/notes" `
  -H "X-API-Key: test" `
  -H "Content-Type: application/json" `
  -d '{\"title\":\"Docker Note\",\"content\":\"Persisted in container!\"}'
```

**For Bash/Linux/Mac:**

```bash
curl http://localhost:8080/health
curl -X POST http://localhost:8080/v1/notes \
  -H "X-API-Key: test" \
  -H "Content-Type: application/json" \
  -d '{"title": "Docker Note", "content": "Persisted in container!"}'
```

## Key Features Demonstrated

### 1. **Type Safety**

```dart
// Compile-time type checking
Future<Note?> getNoteById(String id) => 
    (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

// Type-safe insertions
final note = NotesCompanion(
  id: Value(uuid.v4()),
  title: Value(title),
  content: Value(content.isEmpty ? null : content),
  createdAt: Value(DateTime.now()),
  updatedAt: Value(DateTime.now()),
);
```

### 2. **Automatic Migrations**

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
  },
);
```

### 3. **Query Builder**

```dart
// Pagination
Future<List<Note>> getNotesPage(int page, int limit) {
  final offset = (page - 1) * limit;
  return (select(notes)..limit(limit, offset: offset)).get();
}

// Counting
Future<int> countNotes() async {
  final query = selectOnly(notes)..addColumns([notes.id.count()]);
  final result = await query.getSingle();
  return result.read(notes.id.count()) ?? 0;
}
```

### 4. **Testing Support**

```dart
// In-memory database for tests
db = AppDatabase.forTesting(NativeDatabase.memory());
```

## Troubleshooting

### **PowerShell-Specific Issues:**

1. **Line continuation errors**
   ```powershell
   # ❌ Wrong - PowerShell doesn't use backslashes
   curl -X POST http://localhost:8080/v1/notes \
     -H "X-API-Key: test"

   # ✅ Correct - Use backticks for line continuation
   curl.exe -X POST "http://localhost:8080/v1/notes" `
     -H "X-API-Key: test"
   ```

2. **Quote escaping issues**
   ```powershell
   # ❌ Wrong - Single quotes don't escape properly
   curl.exe -d '{"title":"test"}'

   # ✅ Correct - Escape quotes with backslashes
   curl.exe -d '{\"title\":\"test\"}'

   # ✅ Alternative - Use double quotes and escape inner quotes
   curl.exe -d "{\`"title\`":\`"test\`"}"
   ```

3. **curl vs curl.exe**
   ```powershell
   # ❌ May use PowerShell's Invoke-WebRequest alias
   curl http://localhost:8080/health

   # ✅ Use actual curl.exe
   curl.exe http://localhost:8080/health
   ```

### **Common Issues:**

1. **"database.g.dart not found"**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **"Multiple database instances" warning**
   - This is normal in tests
   - Each test creates its own in-memory database
   - Warning can be ignored for test scenarios

3. **Database file permissions**
   ```bash
   # Ensure write permissions
   chmod 664 notes.db
   ```

4. **Port already in use**
   ```bash
   # Use different port
   PORT=8081 dart run bin/server.dart
   ```

## Benefits of Drift Implementation

### ✅ **Advantages:**

- **Type Safety**: Compile-time checking prevents runtime errors
- **Code Generation**: Reduces boilerplate and ensures consistency
- **SQLite Integration**: Zero-configuration embedded database
- **Testing**: Easy in-memory database for unit tests
- **Migration Support**: Automatic schema management
- **Performance**: Optimized queries and connection pooling

### ⚠️ **Trade-offs:**

- **Build Step**: Requires code generation (`build_runner`)
- **Learning Curve**: Drift-specific syntax and patterns
- **File Size**: Generated code adds to project size
- **Single Instance**: SQLite doesn't scale horizontally

## Next Steps

To extend the Drift implementation:

1. **Add More Tables**: Define additional `Table` classes
2. **Complex Queries**: Use joins, subqueries, and aggregations
3. **Migrations**: Implement schema versioning for production
4. **Connection Pooling**: Configure for high-concurrency scenarios
5. **Backup/Restore**: Add database backup functionality

---

**The Drift implementation provides a robust, type-safe foundation for data
persistence that scales from development to production!** 🚀
