import 'todo.dart';
import 'todo_repository_interface.dart';
import 'data/local/todo_local_data_source.dart';
import 'data/remote/todo_remote_data_source.dart';

class TodoRepository implements TodoRepositoryInterface {
  TodoRepository({
    required TodoLocalDataSource local,
    required TodoRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  final TodoLocalDataSource _local;
  final TodoRemoteDataSource _remote;

  // ローカルにデータがあればそれを返す。なければ Remote から取得してキャッシュ。
  @override
  Future<List<Todo>> findAll() async {
    final local = await _local.findAll();
    if (local.isNotEmpty) return local;
    return _syncFromRemote();
  }

  // Remote から全件取得してローカルを上書きする（明示的同期）
  Future<List<Todo>> syncFromRemote() => _syncFromRemote();

  Future<List<Todo>> _syncFromRemote() async {
    final remote = await _remote.fetchAll();
    await _local.deleteAll();
    await _local.insertAll(remote);
    return remote;
  }

  @override
  Future<void> insert(Todo todo) => _local.insert(todo);

  @override
  Future<void> update(Todo todo) => _local.update(todo);

  @override
  Future<void> delete(String id) => _local.delete(id);
}
