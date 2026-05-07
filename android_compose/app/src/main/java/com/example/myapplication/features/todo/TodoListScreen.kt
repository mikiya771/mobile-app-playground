package com.example.myapplication.features.todo

import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

// Screen 層で変換（モデルに UI を持たせない）
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
fun TodoListScreen() {
    Scaffold(
        topBar = {
            TopAppBar(title = { Text("TODO") })
        },
        floatingActionButton = {
            FloatingActionButton(onClick = {}) {
                Icon(Icons.Default.Add, contentDescription = "追加")
            }
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            FilterTabBar(selected = "ALL", onSelect = {})
            LazyColumn {
                items(dummyTodos, key = { it.id }) { todo ->
                    TodoCard(todo = todo)
                }
            }
        }
    }
}

@Composable
fun FilterTabBar(selected: String, onSelect: (String) -> Unit) {
    Row(modifier = Modifier.fillMaxWidth()) {
        listOf("ALL", "ACTIVE", "COMPLETED").forEach { label ->
            TextButton(
                onClick = { onSelect(label) },
                modifier = Modifier.weight(1f),
            ) {
                Text(
                    text = label,
                    color = if (label == selected) {
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
fun TodoCard(todo: Todo) {
    Card(
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
            if (todo.isCompleted) {
                Icon(
                    Icons.Default.Check,
                    contentDescription = "完了",
                    modifier = Modifier.padding(start = 8.dp),
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
