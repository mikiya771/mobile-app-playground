package com.example.androidxml.features.todo.data.local

import androidx.lifecycle.LiveData
import androidx.lifecycle.map
import com.example.androidxml.features.todo.Todo

class TodoLocalDataSource(private val dao: TodoDao) {
    fun observeAll(): LiveData<List<Todo>> = dao.observeAll().map { list -> list.map { it.toDomain() } }
    suspend fun findAllIds(): List<String> = dao.findAllIds()
    suspend fun insert(todo: Todo) = dao.insert(todo.toEntity())
    suspend fun update(todo: Todo) = dao.update(todo.toEntity())
    suspend fun delete(id: String) = dao.delete(id)
}
