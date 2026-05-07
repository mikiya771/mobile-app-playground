package com.example.myapplication.features.todo

import kotlinx.coroutines.flow.Flow

interface TodoRepositoryInterface {
    fun observeAll(): Flow<List<Todo>>
    suspend fun insert(todo: Todo)
    suspend fun update(todo: Todo)
    suspend fun delete(id: String)
    suspend fun sync()
}
