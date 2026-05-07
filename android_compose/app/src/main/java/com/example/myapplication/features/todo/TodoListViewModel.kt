package com.example.myapplication.features.todo

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class TodoListState(
    val todos: List<Todo> = emptyList(),
    val filter: TodoFilter = TodoFilter.ALL,
    val isLoading: Boolean = true,
    val isSyncing: Boolean = false,
    val error: String? = null,
) {
    val filtered: List<Todo>
        get() = when (filter) {
            TodoFilter.ALL       -> todos
            TodoFilter.ACTIVE    -> todos.filter { !it.isCompleted }
            TodoFilter.COMPLETED -> todos.filter { it.isCompleted }
        }
}

class TodoListViewModel(
    private val repository: TodoRepositoryInterface,
) : ViewModel() {

    private val _state = MutableStateFlow(TodoListState())
    val state: StateFlow<TodoListState> = _state.asStateFlow()

    init {
        viewModelScope.launch {
            repository.observeAll().collect { todos ->
                _state.update { it.copy(todos = todos, isLoading = false) }
            }
        }
    }

    fun setFilter(filter: TodoFilter) {
        _state.update { it.copy(filter = filter) }
    }

    fun toggle(id: String) {
        viewModelScope.launch {
            val todo = _state.value.todos.find { it.id == id } ?: return@launch
            repository.update(todo.copy(isCompleted = !todo.isCompleted))
        }
    }

    fun delete(id: String) {
        viewModelScope.launch { repository.delete(id) }
    }

    fun sync() {
        viewModelScope.launch {
            _state.update { it.copy(isSyncing = true, error = null) }
            try {
                repository.sync()
            } catch (e: Exception) {
                _state.update { it.copy(error = e.message) }
            } finally {
                _state.update { it.copy(isSyncing = false) }
            }
        }
    }

    class Factory(private val repository: TodoRepositoryInterface) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            TodoListViewModel(repository) as T
    }
}
