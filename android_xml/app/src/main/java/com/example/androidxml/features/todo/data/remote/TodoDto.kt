package com.example.androidxml.features.todo.data.remote

import com.example.androidxml.features.todo.Todo
import com.example.androidxml.features.todo.TodoPriority
import com.google.gson.annotations.SerializedName

data class TodoDto(
    @SerializedName("id") val id: Int,
    @SerializedName("title") val title: String,
    @SerializedName("completed") val completed: Boolean,
)

fun TodoDto.toEntity() = Todo(
    id = "api_$id", title = title, isCompleted = completed,
    description = "APIから取得", priority = TodoPriority.MEDIUM,
    createdAt = System.currentTimeMillis(),
)
