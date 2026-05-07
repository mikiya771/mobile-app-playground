package com.example.myapplication.auth

import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import org.json.JSONObject

@Composable
fun LoginWebViewScreen(onLoginSuccess: (String) -> Unit) {
    AndroidView(
        factory = { context ->
            WebView(context).apply {
                settings.javaScriptEnabled = true
                webViewClient = WebViewClient()
                addJavascriptInterface(
                    FlutterAuthBridge(onLoginSuccess),
                    "FlutterAuth",
                )
                loadUrl("file:///android_asset/login.html")
            }
        },
        modifier = Modifier.fillMaxSize(),
    )
}

private class FlutterAuthBridge(
    private val onLoginSuccess: (String) -> Unit,
) {
    private val mainScope = MainScope()

    // JS から呼ばれる唯一の入口（@JavascriptInterface のないメソッドは JS からアクセス不可）
    @JavascriptInterface
    fun postMessage(json: String) {
        mainScope.launch {
            val data = JSONObject(json)
            when (data.getString("type")) {
                "login" -> onLoginSuccess(data.getString("token"))
                "oauth" -> onLoginSuccess("oauth_mock_token")
            }
        }
    }
}
