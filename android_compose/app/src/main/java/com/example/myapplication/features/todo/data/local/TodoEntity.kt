package com.example.myapplication.features.todo.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.example.myapplication.features.todo.Todo
import com.example.myapplication.features.todo.TodoPriority

@Entity(tableName = "todos")
data class TodoEntity(
    @PrimaryKey val id: String,
    val title: String,
    val description: String = "",
    val isCompleted: Boolean = false,
    val priority: String = "MEDIUM",
    val createdAt: Long,
)

fun TodoEntity.toDomain() = Todo(
    id = id,
    title = title,
    description = description,
    isCompleted = isCompleted,
    priority = TodoPriority.valueOf(priority),
    createdAt = createdAt,
)

fun Todo.toEntity() = TodoEntity(
    id = id,
    title = title,
    description = description,
    isCompleted = isCompleted,
    priority = priority.name,
    createdAt = createdAt,
)
