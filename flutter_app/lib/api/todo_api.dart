import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/todo.dart';

class TodoApi {
  static final TodoApi _instance = TodoApi._();
  factory TodoApi() => _instance;
  TodoApi._();

  final _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<Todo>> fetchTodos({int limit = 20}) async {
    final res = await _dio.get('/todos', queryParameters: {'_limit': limit});
    return (res.data as List).map((j) => Todo.fromApi(j as Map<String, dynamic>)).toList();
  }
}
