package com.example.androidxml

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.example.androidxml.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Step 1: primary カラーでテキストを着色（ViewBinding の型安全なアクセス）
        binding.helloText.setTextColor(
            ContextCompat.getColor(this, R.color.purple_500)
        )
    }
}
