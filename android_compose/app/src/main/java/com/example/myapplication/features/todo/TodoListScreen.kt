package com.example.myapplication.features.todo

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel

val TodoPriority.color: Color
    get() = when (this) {
        TodoPriority.LOW    -> Color(0xFF4CAF50)
        TodoPriority.MEDIUM -> Color(0xFFFF9800)
        TodoPriority.HIGH   -> Color(0xFFF44336)
    }

val TodoPriority.label: String
    get() = when (this) {
        TodoPriority.LOW    -> "低"
        TodoPriority.MEDIUM -> "中"
        TodoPriority.HIGH   -> "高"
    }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TodoListScreen(
    viewModel: TodoListViewModel,
    onTodoClick: (String) -> Unit = {},
    onAddClick: () -> Unit = {},
    onOpenWeb: (String) -> Unit = {},
) {
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("TODO") })
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onAddClick) {
                Icon(Icons.Default.Add, contentDescription = "追加")
            }
        },
    ) { innerPadding ->
        if (state.isLoading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center,
            ) {
                CircularProgressIndicator()
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
            ) {
                FilterTabBar(
                    selected = state.filter,
                    onSelect = { viewModel.setFilter(it) },
                )
                LazyColumn {
                    items(state.filtered, key = { it.id }) { todo ->
                        SwipableTodoCard(
                            todo = todo,
                            onToggle = { viewModel.toggle(it) },
                            onDelete = { viewModel.delete(it) },
                            onClick = { onTodoClick(todo.id) },
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SwipableTodoCard(
    todo: Todo,
    onToggle: (String) -> Unit,
    onDelete: (String) -> Unit,
    onClick: () -> Unit = {},
) {
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { it == SwipeToDismissBoxValue.EndToStart },
    )

    LaunchedEffect(dismissState.currentValue) {
        if (dismissState.currentValue == SwipeToDismissBoxValue.EndToStart) {
            onDelete(todo.id)
        }
    }

    SwipeToDismissBox(
        state = dismissState,
        backgroundContent = {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                contentAlignment = Alignment.CenterEnd,
            ) {
                Icon(Icons.Default.Delete, contentDescription = "削除", tint = Color.Red)
            }
        },
    ) {
        TodoCard(todo = todo, onToggle = onToggle, onClick = onClick)
    }
}

@Composable
fun FilterTabBar(selected: TodoFilter, onSelect: (TodoFilter) -> Unit) {
    Row(modifier = Modifier.fillMaxWidth()) {
        TodoFilter.entries.forEach { f ->
            TextButton(
                onClick = { onSelect(f) },
                modifier = Modifier.weight(1f),
            ) {
                Text(
                    text = f.name,
                    color = if (f == selected) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.onSurface
                    },
                )
            }
        }
    }
}

@Composable
fun TodoCard(
    todo: Todo,
    onToggle: (String) -> Unit = {},
    onClick: () -> Unit = {},
) {
    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(text = todo.title, style = MaterialTheme.typography.bodyLarge)
                if (todo.description.isNotBlank()) {
                    Text(
                        text = todo.description,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            PriorityBadge(priority = todo.priority)
            IconButton(onClick = { onToggle(todo.id) }) {
                Icon(
                    Icons.Default.Check,
                    contentDescription = "完了切替",
                    tint = if (todo.isCompleted) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant
                    },
                )
            }
        }
    }
}

@Composable
fun PriorityBadge(priority: TodoPriority) {
    Surface(
        color = priority.color,
        shape = RoundedCornerShape(4.dp),
    ) {
        Text(
            text = priority.label,
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
            style = MaterialTheme.typography.labelSmall,
            color = Color.White,
        )
    }
}
