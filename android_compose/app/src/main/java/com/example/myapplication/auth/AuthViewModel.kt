package com.example.myapplication.auth

import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

data class AuthState(
    val isLoggedIn: Boolean = false,
    val token: String? = null,
)

class AuthViewModel : ViewModel() {
    private val _state = MutableStateFlow(AuthState())
    val state: StateFlow<AuthState> = _state.asStateFlow()

    fun loginWithToken(token: String) {
        _state.update { it.copy(isLoggedIn = true, token = token) }
    }

    fun logout() {
        _state.update { it.copy(isLoggedIn = false, token = null) }
    }
}
