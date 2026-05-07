package com.example.myapplication.features.todo

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TodoDetailScreen(
    todoId: String,
    viewModel: TodoListViewModel,
    onBack: () -> Unit,
) {
    val state by viewModel.state.collectAsState()
    val todo = state.todos.find { it.id == todoId }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("詳細") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                },
            )
        },
    ) { innerPadding ->
        if (todo == null) {
            Text("Not found", modifier = Modifier.padding(innerPadding))
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(text = todo.title, style = MaterialTheme.typography.headlineMedium)
                if (todo.description.isNotBlank()) {
                    Text(text = todo.description, style = MaterialTheme.typography.bodyMedium)
                }
                Text(text = "優先度: ${todo.priority.label}", style = MaterialTheme.typography.bodySmall)
                Text(
                    text = if (todo.isCompleted) "完了済み" else "未完了",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
    }
}
