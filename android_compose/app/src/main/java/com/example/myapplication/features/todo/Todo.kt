package com.example.myapplication.features.todo

data class Todo(
    val id: String,
    val title: String,
    val description: String = "",
    val isCompleted: Boolean = false,
    val priority: TodoPriority = TodoPriority.MEDIUM,
    val createdAt: Long = System.currentTimeMillis(),
)

enum class TodoPriority { LOW, MEDIUM, HIGH }
enum class TodoFilter { ALL, ACTIVE, COMPLETED }

val dummyTodos = listOf(
    Todo(id = "1", title = "Jetpack Compose を学ぶ", description = "公式ドキュメントから始める", priority = TodoPriority.HIGH),
    Todo(id = "2", title = "Room で永続化する", description = "Entity / Dao / Database の3層", isCompleted = true, priority = TodoPriority.MEDIUM),
    Todo(id = "3", title = "Navigation Compose で画面遷移", priority = TodoPriority.LOW),
    Todo(id = "4", title = "Ktor Client で API 通信", priority = TodoPriority.MEDIUM),
    Todo(id = "5", title = "OAuth フローを実装する", priority = TodoPriority.HIGH),
)
