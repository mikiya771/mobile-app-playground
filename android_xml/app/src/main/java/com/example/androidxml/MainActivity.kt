package com.example.androidxml

import android.graphics.Canvas
import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.ItemTouchHelper
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.example.androidxml.databinding.ActivityMainBinding
import com.example.androidxml.features.todo.TodoAdapter
import com.example.androidxml.features.todo.TodoFilter
import com.example.androidxml.features.todo.TodoListViewModel

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private val viewModel: TodoListViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setSupportActionBar(binding.toolbar)

        val adapter = TodoAdapter(
            onToggle = { viewModel.toggle(it) },
        )

        binding.recyclerView.layoutManager = LinearLayoutManager(this)
        binding.recyclerView.adapter = adapter

        // スワイプ削除（ItemTouchHelper）
        ItemTouchHelper(object : ItemTouchHelper.SimpleCallback(0, ItemTouchHelper.LEFT) {
            override fun onMove(rv: RecyclerView, vh: RecyclerView.ViewHolder, t: RecyclerView.ViewHolder) = false
            override fun onSwiped(viewHolder: RecyclerView.ViewHolder, direction: Int) {
                val pos = viewHolder.bindingAdapterPosition
                val todo = adapter.currentList[pos]
                viewModel.delete(todo.id)
            }
        }).attachToRecyclerView(binding.recyclerView)

        // フィルタータブ
        binding.tabAll.setOnClickListener { viewModel.setFilter(TodoFilter.ALL) }
        binding.tabActive.setOnClickListener { viewModel.setFilter(TodoFilter.ACTIVE) }
        binding.tabCompleted.setOnClickListener { viewModel.setFilter(TodoFilter.COMPLETED) }

        viewModel.filtered.observe(this) { adapter.submitList(it) }
        viewModel.filter.observe(this) { selected ->
            val primary = ContextCompat.getColor(this, R.color.purple_500)
            val normal = ContextCompat.getColor(this, android.R.color.darker_gray)
            binding.tabAll.setTextColor(if (selected == TodoFilter.ALL) primary else normal)
            binding.tabActive.setTextColor(if (selected == TodoFilter.ACTIVE) primary else normal)
            binding.tabCompleted.setTextColor(if (selected == TodoFilter.COMPLETED) primary else normal)
        }
    }
}
