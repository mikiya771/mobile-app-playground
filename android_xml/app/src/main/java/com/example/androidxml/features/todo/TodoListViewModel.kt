package com.example.androidxml.features.todo

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.map

data class TodoListState(
    val todos: List<Todo> = dummyTodos,
    val filter: TodoFilter = TodoFilter.ALL,
    val isLoading: Boolean = false,
    val isSyncing: Boolean = false,
    val error: String? = null,
)

class TodoListViewModel : ViewModel() {
    private val _state = MutableLiveData(TodoListState())

    val filtered: LiveData<List<Todo>> = _state.map { state ->
        when (state.filter) {
            TodoFilter.ALL       -> state.todos
            TodoFilter.ACTIVE    -> state.todos.filter { !it.isCompleted }
            TodoFilter.COMPLETED -> state.todos.filter { it.isCompleted }
        }
    }

    val filter: LiveData<TodoFilter> = _state.map { it.filter }

    fun setFilter(filter: TodoFilter) {
        _state.value = _state.value?.copy(filter = filter)
    }

    fun toggle(id: String) {
        val todos = _state.value?.todos ?: return
        _state.value = _state.value?.copy(
            todos = todos.map { if (it.id == id) it.copy(isCompleted = !it.isCompleted) else it }
        )
    }

    fun delete(id: String) {
        val todos = _state.value?.todos ?: return
        _state.value = _state.value?.copy(todos = todos.filter { it.id != id })
    }
}
