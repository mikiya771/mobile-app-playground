package com.example.myapplication

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.example.myapplication.features.todo.TodoDetailScreen
import com.example.myapplication.features.todo.TodoListScreen
import com.example.myapplication.features.todo.TodoListViewModel
import com.example.myapplication.webview.WebViewScreen

@Composable
fun AppNavGraph(
    navController: NavHostController,
    todoViewModel: TodoListViewModel,
) {
    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            TodoListScreen(
                viewModel = todoViewModel,
                onTodoClick = { id -> navController.navigate("todo/$id") },
                onOpenWeb = { url -> navController.navigate("webview?url=$url") },
            )
        }
        composable(
            route = "todo/{id}",
            arguments = listOf(navArgument("id") { type = NavType.StringType }),
        ) { backStackEntry ->
            val id = backStackEntry.arguments?.getString("id") ?: return@composable
            TodoDetailScreen(
                todoId = id,
                viewModel = todoViewModel,
                onBack = { navController.popBackStack() },
            )
        }
        composable(
            route = "webview?url={url}",
            arguments = listOf(navArgument("url") { type = NavType.StringType; defaultValue = "" }),
        ) { backStackEntry ->
            val url = backStackEntry.arguments?.getString("url") ?: ""
            WebViewScreen(url = url, onBack = { navController.popBackStack() })
        }
    }
}
