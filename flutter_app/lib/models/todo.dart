import 'package:uuid/uuid.dart';
import '../config/app_config.dart';

enum TodoPriority { low, medium, high }

extension TodoPriorityX on TodoPriority {
  String get label => switch (this) {
        TodoPriority.low => '低',
        TodoPriority.medium => '中',
        TodoPriority.high => '高',
      };
}

class Todo {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final TodoPriority priority;
  final DateTime createdAt;

  Todo({
    String? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = TodoPriority.medium,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get detailUrl => '${AppConfig.baseUrl}/todos/$id';

  Todo copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    TodoPriority? priority,
  }) =>
      Todo(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        priority: priority ?? this.priority,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted ? 1 : 0,
        'priority': priority.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        isCompleted: (map['isCompleted'] as int) == 1,
        priority: TodoPriority.values.firstWhere(
          (e) => e.name == map['priority'],
          orElse: () => TodoPriority.medium,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      );

  factory Todo.fromApi(Map<String, dynamic> json) => Todo(
        id: 'api_${json['id']}',
        title: json['title'] as String,
        description: 'APIから取得',
        isCompleted: json['completed'] as bool,
      );
}
