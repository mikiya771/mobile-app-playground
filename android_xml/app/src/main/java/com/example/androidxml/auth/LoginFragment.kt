package com.example.androidxml.auth

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.browser.customtabs.CustomTabsIntent
import androidx.core.net.toUri
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.navigation.fragment.findNavController
import com.example.androidxml.MainActivity
import com.example.androidxml.R
import com.example.androidxml.databinding.FragmentLoginBinding
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import org.json.JSONObject

class LoginFragment : Fragment() {
    private var _binding: FragmentLoginBinding? = null
    private val binding get() = _binding!!
    private val authViewModel: AuthViewModel by activityViewModels()

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentLoginBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        binding.webView.apply {
            settings.javaScriptEnabled = true
            webViewClient = WebViewClient()
            addJavascriptInterface(
                FlutterAuthBridge(
                    onLoginSuccess = { token ->
                        authViewModel.loginWithToken(token)
                    },
                    onStartOAuth = {
                        val uri = "file:///android_asset/oauth/authorize.html".toUri()
                        CustomTabsIntent.Builder().build()
                            .launchUrl(requireContext(), uri)
                    },
                ),
                "FlutterAuth",
            )
            loadUrl("file:///android_asset/login.html")
        }
    }

    override fun onDestroyView() {
        // Fragment 破棄時に JS Interface を解除（リーク防止）
        binding.webView.removeJavascriptInterface("FlutterAuth")
        super.onDestroyView()
        _binding = null
    }
}

private class FlutterAuthBridge(
    private val onLoginSuccess: (String) -> Unit,
    private val onStartOAuth: () -> Unit,
) {
    private val mainScope = MainScope()

    @JavascriptInterface
    fun postMessage(json: String) {
        mainScope.launch {
            val data = JSONObject(json)
            when (data.getString("type")) {
                "login" -> onLoginSuccess(data.getString("token"))
                "oauth" -> onStartOAuth()
            }
        }
    }
}
