package com.example.myapplication.features.todo

import com.example.myapplication.features.todo.data.local.TodoLocalDataSource
import com.example.myapplication.features.todo.data.remote.TodoRemoteDataSource
import com.example.myapplication.features.todo.data.remote.toEntity
import kotlinx.coroutines.flow.Flow

class TodoRepository(
    private val local: TodoLocalDataSource,
    private val remote: TodoRemoteDataSource = TodoRemoteDataSource(),
) : TodoRepositoryInterface {

    override fun observeAll(): Flow<List<Todo>> = local.observeAll()

    override suspend fun insert(todo: Todo) = local.insert(todo)

    override suspend fun update(todo: Todo) = local.update(todo)

    override suspend fun delete(id: String) = local.delete(id)

    override suspend fun sync() {
        val dtos = remote.fetchAll()
        val existing = local.findAllIds().toSet()
        dtos.filter { "api_${it.id}" !in existing }
            .forEach { local.insert(it.toEntity()) }
    }
}
