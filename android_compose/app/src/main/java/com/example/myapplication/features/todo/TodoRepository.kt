package com.example.myapplication.features.todo

import com.example.myapplication.features.todo.data.local.TodoLocalDataSource
import kotlinx.coroutines.flow.Flow

class TodoRepository(
    private val local: TodoLocalDataSource,
) : TodoRepositoryInterface {

    override fun observeAll(): Flow<List<Todo>> = local.observeAll()

    override suspend fun insert(todo: Todo) = local.insert(todo)

    override suspend fun update(todo: Todo) = local.update(todo)

    override suspend fun delete(id: String) = local.delete(id)

    // Step 10 で remote を追加する
    override suspend fun sync() = Unit
}
