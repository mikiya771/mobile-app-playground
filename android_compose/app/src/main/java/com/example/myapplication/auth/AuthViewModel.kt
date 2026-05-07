package com.example.myapplication.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

data class AuthState(
    val isLoggedIn: Boolean = false,
    val token: String? = null,
)

class AuthViewModel(private val tokenStorage: TokenStorage) : ViewModel() {
    private val _state = MutableStateFlow(AuthState())
    val state: StateFlow<AuthState> = _state.asStateFlow()

    init {
        // アプリ起動時にトークンを確認して自動ログイン
        val token = tokenStorage.read()
        _state.update { it.copy(isLoggedIn = token != null, token = token) }
    }

    fun loginWithToken(token: String) {
        tokenStorage.write(token)
        _state.update { it.copy(isLoggedIn = true, token = token) }
    }

    fun logout() {
        tokenStorage.delete()
        _state.update { it.copy(isLoggedIn = false, token = null) }
    }

    // Step 15 で追加するOAuthコールバック処理
    fun handleOAuthCallback(code: String?) {
        if (code != null) loginWithToken("oauth_token_$code")
    }

    class Factory(private val tokenStorage: TokenStorage) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            AuthViewModel(tokenStorage) as T
    }
}
