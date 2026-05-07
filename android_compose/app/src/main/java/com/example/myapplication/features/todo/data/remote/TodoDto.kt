package com.example.myapplication.features.todo.data.remote

import com.example.myapplication.features.todo.Todo
import com.example.myapplication.features.todo.TodoPriority
import kotlinx.serialization.Serializable

@Serializable
data class TodoDto(
    val id: Int,
    val title: String,
    val completed: Boolean,
)

fun TodoDto.toEntity() = Todo(
    id = "api_$id",
    title = title,
    isCompleted = completed,
    description = "APIから取得",
    priority = TodoPriority.MEDIUM,
    createdAt = System.currentTimeMillis(),
)
