import 'package:dio/dio.dart';
import '../../todo.dart';
import 'todo_dto.dart';

class TodoRemoteDataSource {
  TodoRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Todo>> fetchAll() async {
    final response = await _dio.get<List<dynamic>>('/todos');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(TodoDto.fromJson)
        .map((dto) => dto.toEntity())
        .toList();
  }
}
