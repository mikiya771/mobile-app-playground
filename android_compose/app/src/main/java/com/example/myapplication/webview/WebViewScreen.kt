package com.example.myapplication.webview

import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.net.toUri

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WebViewScreen(url: String, onBack: () -> Unit) {
    var isLoading by remember { mutableStateOf(true) }
    var currentUrl by remember { mutableStateOf(url) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(currentUrl.takeIf { it.isNotBlank() } ?: "WebView") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                },
            )
        },
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            AndroidView(
                factory = { context ->
                    WebView(context).apply {
                        settings.javaScriptEnabled = true
                        webViewClient = object : WebViewClient() {
                            override fun onPageFinished(view: WebView, url: String) {
                                isLoading = false
                                currentUrl = url
                            }

                            // ホワイトリスト制御（Step 12）
                            override fun shouldOverrideUrlLoading(
                                view: WebView,
                                request: WebResourceRequest,
                            ): Boolean {
                                val host = request.url.host ?: return true
                                if (WebViewConfig.isAllowed(host)) return false
                                // ホワイトリスト外 → Chrome Custom Tabs で外部に渡す
                                CustomTabsIntent.Builder().build()
                                    .launchUrl(context, request.url.toString().toUri())
                                return true
                            }
                        }
                        if (url.isNotBlank()) loadUrl(url)
                    }
                },
                modifier = Modifier.fillMaxSize(),
            )
            if (isLoading && url.isNotBlank()) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            }
        }
    }
}
