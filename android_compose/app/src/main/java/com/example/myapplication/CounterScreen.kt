package com.example.myapplication

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

// Stateful: 状態を持つ親（Flutter の StatefulWidget に相当）
@Composable
fun CounterScreen() {
    var count by remember { mutableStateOf(0) }

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        CounterDisplay(count = count)
        Spacer(modifier = Modifier.height(24.dp))
        CounterButtons(
            onIncrement = { count++ },
            onDecrement = { count-- },
        )
        Spacer(modifier = Modifier.height(16.dp))
        // 追加課題: count の符号でラベルを切り替える
        CounterLabel(count = count)
    }
}

// Stateless: 引数を受け取って描画するだけ（Flutter の StatelessWidget に相当）
@Composable
fun CounterDisplay(count: Int) {
    Text(
        text = count.toString(),
        style = MaterialTheme.typography.displayLarge,
        color = MaterialTheme.colorScheme.primary,
    )
}

// Stateless: コールバックを受け取るだけ
@Composable
fun CounterButtons(
    onIncrement: () -> Unit,
    onDecrement: () -> Unit,
) {
    Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
        Button(onClick = onDecrement) { Text("-") }
        Button(onClick = onIncrement) { Text("+") }
    }
}

// 追加課題: count > 0 / < 0 / == 0 でラベルを切り替える
@Composable
fun CounterLabel(count: Int) {
    val label = when {
        count > 0 -> "プラス"
        count < 0 -> "マイナス"
        else      -> "ゼロ"
    }
    Text(text = label, style = MaterialTheme.typography.titleMedium)
}
