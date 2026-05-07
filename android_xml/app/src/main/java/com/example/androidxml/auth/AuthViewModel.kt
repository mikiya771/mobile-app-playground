package com.example.androidxml.auth

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider

data class AuthState(val isLoggedIn: Boolean = false, val token: String? = null)

class AuthViewModel(private val tokenStorage: TokenStorage) : ViewModel() {
    private val _state = MutableLiveData(AuthState())
    val state: LiveData<AuthState> = _state

    init {
        val saved = tokenStorage.read()
        if (saved != null) _state.value = AuthState(isLoggedIn = true, token = saved)
    }

    fun loginWithToken(token: String) {
        tokenStorage.write(token)
        _state.value = AuthState(isLoggedIn = true, token = token)
    }

    fun logout() {
        tokenStorage.delete()
        _state.value = AuthState(isLoggedIn = false, token = null)
    }

    fun handleOAuthCallback(code: String) {
        loginWithToken("oauth_token_$code")
    }

    class Factory(private val tokenStorage: TokenStorage) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            AuthViewModel(tokenStorage) as T
    }
}
