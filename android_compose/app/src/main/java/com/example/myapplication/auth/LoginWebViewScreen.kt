package com.example.myapplication.auth

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

// Step 13 で WebView + JS Bridge に差し替える
@Composable
fun LoginWebViewScreen(onLoginSuccess: (String) -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text("ログイン画面")
        Button(onClick = { onLoginSuccess("mock_token") }) {
            Text("ログイン（モック）")
        }
    }
}
