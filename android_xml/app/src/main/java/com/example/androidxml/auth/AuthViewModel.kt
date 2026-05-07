package com.example.androidxml.auth

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

data class AuthState(val isLoggedIn: Boolean = false, val token: String? = null)

// Step 14 で TokenStorage を追加する
class AuthViewModel : ViewModel() {
    private val _state = MutableLiveData(AuthState())
    val state: LiveData<AuthState> = _state

    fun loginWithToken(token: String) {
        _state.value = AuthState(isLoggedIn = true, token = token)
    }

    fun logout() {
        _state.value = AuthState(isLoggedIn = false, token = null)
    }
}
