import '../../todo.dart';

class TodoDto {
  const TodoDto({
    required this.id,
    required this.title,
    required this.completed,
  });

  final int id;
  final String title;
  final bool completed;

  factory TodoDto.fromJson(Map<String, dynamic> json) => TodoDto(
        id: json['id'] as int,
        title: json['title'] as String,
        completed: json['completed'] as bool,
      );

  Todo toEntity() => Todo(
        id: id.toString(),
        title: title,
        isCompleted: completed,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
}
