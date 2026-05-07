package com.example.myapplication

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.rememberNavController
import com.example.myapplication.auth.AuthViewModel
import com.example.myapplication.auth.TokenStorage
import com.example.myapplication.features.todo.TodoListViewModel
import com.example.myapplication.features.todo.TodoRepository
import com.example.myapplication.features.todo.data.local.AppDatabase
import com.example.myapplication.features.todo.data.local.TodoLocalDataSource
import com.example.myapplication.ui.theme.MyApplicationTheme

class MainActivity : ComponentActivity() {
    private var authViewModelRef: AuthViewModel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val db = AppDatabase.getInstance(this)
        val repository = TodoRepository(TodoLocalDataSource(db.todoDao()))
        val tokenStorage = TokenStorage(this)

        setContent {
            MyApplicationTheme {
                val navController = rememberNavController()
                val todoViewModel: TodoListViewModel = viewModel(
                    factory = TodoListViewModel.Factory(repository),
                )
                val authViewModel: AuthViewModel = viewModel(
                    factory = AuthViewModel.Factory(tokenStorage),
                )
                authViewModelRef = authViewModel
                AppNavGraph(
                    navController = navController,
                    todoViewModel = todoViewModel,
                    authViewModel = authViewModel,
                )
            }
        }
    }

    // Chrome Custom Tabs から todoapp://callback?code=xxx で戻ってくる
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val uri = intent.data ?: return
        if (uri.scheme == "todoapp" && uri.host == "callback") {
            val code = uri.getQueryParameter("code")
            authViewModelRef?.handleOAuthCallback(code)
        }
    }
}
