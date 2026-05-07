package com.example.myapplication.features.todo

data class Todo(
    val id: String,
    val title: String,
    val isCompleted: Boolean = false,
)

val dummyTodos = listOf(
    Todo(id = "1", title = "Jetpack Compose を学ぶ"),
    Todo(id = "2", title = "Room で永続化する", isCompleted = true),
    Todo(id = "3", title = "Navigation Compose で画面遷移"),
    Todo(id = "4", title = "Ktor Client で API 通信"),
    Todo(id = "5", title = "OAuth フローを実装する"),
)
