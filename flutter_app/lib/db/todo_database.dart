import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/todo.dart';

class TodoDatabase {
  static final TodoDatabase _instance = TodoDatabase._();
  factory TodoDatabase() => _instance;
  TodoDatabase._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'todos.db');
    return openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE todos (
          id          TEXT PRIMARY KEY,
          title       TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          isCompleted INTEGER NOT NULL DEFAULT 0,
          priority    TEXT NOT NULL DEFAULT 'medium',
          createdAt   INTEGER NOT NULL
        )
      ''');
    });
  }

  Future<List<Todo>> getAll() async {
    final db = await _database;
    final rows = await db.query('todos', orderBy: 'createdAt DESC');
    return rows.map(Todo.fromMap).toList();
  }

  Future<void> insert(Todo todo) async {
    final db = await _database;
    await db.insert('todos', todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Todo todo) async {
    final db = await _database;
    await db.update('todos', todo.toMap(),
        where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertAllIfAbsent(List<Todo> todos) async {
    final db = await _database;
    final batch = db.batch();
    for (final t in todos) {
      batch.insert('todos', t.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}
