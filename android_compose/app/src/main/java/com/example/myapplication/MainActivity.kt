package com.example.myapplication

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.rememberNavController
import com.example.myapplication.features.todo.TodoListViewModel
import com.example.myapplication.features.todo.TodoRepository
import com.example.myapplication.features.todo.data.local.AppDatabase
import com.example.myapplication.features.todo.data.local.TodoLocalDataSource
import com.example.myapplication.ui.theme.MyApplicationTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val db = AppDatabase.getInstance(this)
        val repository = TodoRepository(TodoLocalDataSource(db.todoDao()))

        setContent {
            MyApplicationTheme {
                val navController = rememberNavController()
                val todoViewModel: TodoListViewModel = viewModel(
                    factory = TodoListViewModel.Factory(repository),
                )
                AppNavGraph(
                    navController = navController,
                    todoViewModel = todoViewModel,
                )
            }
        }
    }
}
