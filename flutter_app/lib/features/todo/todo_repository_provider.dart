import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_repository_interface.dart';
import 'todo_repository.dart';
import 'data/local/todo_local_data_source.dart';
import 'data/remote/todo_remote_data_source.dart';

final _dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
});

final _localDataSourceProvider = Provider<TodoLocalDataSource>((ref) {
  return TodoLocalDataSource();
});

final _remoteDataSourceProvider = Provider<TodoRemoteDataSource>((ref) {
  return TodoRemoteDataSource(ref.read(_dioProvider));
});

final todoRepositoryProvider = Provider<TodoRepositoryInterface>((ref) {
  return TodoRepository(
    local: ref.read(_localDataSourceProvider),
    remote: ref.read(_remoteDataSourceProvider),
  );
});
