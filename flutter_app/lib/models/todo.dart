enum TodoPriority { low, medium, high }

enum TodoFilter { all, active, completed }

class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description = '',
    this.isCompleted = false,
    this.priority = TodoPriority.medium,
  });

  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final TodoPriority priority;
  final DateTime createdAt;

  // 一部だけ変えた新しいインスタンスを返す（イミュータブルな更新）
  Todo copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    TodoPriority? priority,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt,
    );
  }
}
