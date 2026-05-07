package com.example.myapplication.webview

object WebViewConfig {
    val allowedHosts = listOf("localhost", "127.0.0.1", "10.0.2.2")

    fun isAllowed(host: String): Boolean = host in allowedHosts
}
