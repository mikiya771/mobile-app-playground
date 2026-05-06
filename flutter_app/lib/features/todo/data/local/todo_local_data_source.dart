import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../todo.dart';

class TodoLocalDataSource {
  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'todo.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE todos (
          id          TEXT PRIMARY KEY,
          title       TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          isCompleted INTEGER NOT NULL DEFAULT 0,
          priority    TEXT NOT NULL DEFAULT 'medium',
          createdAt   INTEGER NOT NULL
        )
      '''),
    );
  }

  Future<List<Todo>> findAll() async {
    final db = await _database;
    final rows = await db.query('todos', orderBy: 'createdAt ASC');
    return rows.map(_fromRow).toList();
  }

  Future<void> insert(Todo todo) async {
    final db = await _database;
    await db.insert('todos', _toRow(todo),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertAll(List<Todo> todos) async {
    final db = await _database;
    final batch = db.batch();
    for (final todo in todos) {
      batch.insert('todos', _toRow(todo),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(Todo todo) async {
    final db = await _database;
    await db.update('todos', _toRow(todo),
        where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete('todos');
  }

  static Todo _fromRow(Map<String, Object?> row) => Todo(
        id: row['id'] as String,
        title: row['title'] as String,
        description: row['description'] as String,
        isCompleted: (row['isCompleted'] as int) == 1,
        priority: TodoPriority.values.byName(row['priority'] as String),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
      );

  static Map<String, Object?> _toRow(Todo t) => {
        'id': t.id,
        'title': t.title,
        'description': t.description,
        'isCompleted': t.isCompleted ? 1 : 0,
        'priority': t.priority.name,
        'createdAt': t.createdAt.millisecondsSinceEpoch,
      };
}
