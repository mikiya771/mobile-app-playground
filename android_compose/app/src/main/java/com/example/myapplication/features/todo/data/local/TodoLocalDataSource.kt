package com.example.myapplication.features.todo.data.local

import com.example.myapplication.features.todo.Todo
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class TodoLocalDataSource(private val dao: TodoDao) {
    fun observeAll(): Flow<List<Todo>> =
        dao.observeAll().map { list -> list.map { it.toDomain() } }

    suspend fun findAllIds(): List<String> = dao.findAllIds()

    suspend fun insert(todo: Todo) = dao.insert(todo.toEntity())

    suspend fun update(todo: Todo) = dao.update(todo.toEntity())

    suspend fun delete(id: String) = dao.delete(id)
}
