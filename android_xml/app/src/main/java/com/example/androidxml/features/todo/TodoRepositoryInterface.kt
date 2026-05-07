package com.example.androidxml.features.todo

import androidx.lifecycle.LiveData

interface TodoRepositoryInterface {
    fun observeAll(): LiveData<List<Todo>>
    suspend fun insert(todo: Todo)
    suspend fun update(todo: Todo)
    suspend fun delete(id: String)
    suspend fun sync()
}
