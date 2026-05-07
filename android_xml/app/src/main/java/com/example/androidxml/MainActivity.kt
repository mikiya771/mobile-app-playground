package com.example.androidxml

import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.setupActionBarWithNavController
import com.example.androidxml.auth.AuthViewModel
import com.example.androidxml.databinding.ActivityMainBinding
import com.example.androidxml.features.todo.TodoListViewModel
import com.example.androidxml.features.todo.TodoRepository
import com.example.androidxml.features.todo.data.local.AppDatabase
import com.example.androidxml.features.todo.data.local.TodoLocalDataSource

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    private val db by lazy { AppDatabase.getInstance(this) }
    private val repository by lazy { TodoRepository(TodoLocalDataSource(db.todoDao())) }

    val authViewModel: AuthViewModel by viewModels()
    val todoViewModel: TodoListViewModel by viewModels { TodoListViewModel.Factory(repository) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        setSupportActionBar(binding.toolbar)

        val navHostFragment = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        val navController = navHostFragment.navController
        setupActionBarWithNavController(navController)

        // AuthGuard: 認証状態に応じて login / home にリダイレクト
        authViewModel.state.observe(this) { state ->
            val currentDest = navController.currentDestination?.id
            if (!state.isLoggedIn && currentDest != R.id.loginFragment) {
                navController.navigate(R.id.loginFragment) { popUpTo(0) }
            }
            if (state.isLoggedIn && currentDest == R.id.loginFragment) {
                navController.navigate(R.id.action_login_to_home)
            }
        }
    }

    override fun onSupportNavigateUp(): Boolean {
        val navHostFragment = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        return navHostFragment.navController.navigateUp() || super.onSupportNavigateUp()
    }
}
