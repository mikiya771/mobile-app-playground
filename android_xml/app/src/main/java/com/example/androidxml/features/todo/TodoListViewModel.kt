package com.example.androidxml.features.todo

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.map
import androidx.lifecycle.switchMap
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.launch

class TodoListViewModel(private val repository: TodoRepositoryInterface) : ViewModel() {
    private val _filter = MutableLiveData(TodoFilter.ALL)
    val filter: LiveData<TodoFilter> = _filter

    val filtered: LiveData<List<Todo>> = _filter.switchMap { f ->
        repository.observeAll().map { todos ->
            when (f) {
                TodoFilter.ALL       -> todos
                TodoFilter.ACTIVE    -> todos.filter { !it.isCompleted }
                TodoFilter.COMPLETED -> todos.filter { it.isCompleted }
            }
        }
    }

    private val _isSyncing = MutableLiveData(false)
    val isSyncing: LiveData<Boolean> = _isSyncing

    fun setFilter(filter: TodoFilter) { _filter.value = filter }

    fun toggle(id: String) {
        viewModelScope.launch {
            val todo = filtered.value?.find { it.id == id } ?: return@launch
            repository.update(todo.copy(isCompleted = !todo.isCompleted))
        }
    }

    fun delete(id: String) {
        viewModelScope.launch { repository.delete(id) }
    }

    fun sync() {
        viewModelScope.launch {
            _isSyncing.value = true
            try { repository.sync() } finally { _isSyncing.value = false }
        }
    }

    class Factory(private val repository: TodoRepositoryInterface) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            TodoListViewModel(repository) as T
    }
}
