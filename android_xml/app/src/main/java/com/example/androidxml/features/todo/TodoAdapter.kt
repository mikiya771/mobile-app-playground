package com.example.androidxml.features.todo

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.example.androidxml.databinding.ItemTodoBinding

class TodoAdapter(
    private val onToggle: (String) -> Unit = {},
    private val onClick: (String) -> Unit = {},
) : ListAdapter<Todo, TodoAdapter.TodoViewHolder>(DIFF) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): TodoViewHolder {
        val binding = ItemTodoBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return TodoViewHolder(binding)
    }

    override fun onBindViewHolder(holder: TodoViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class TodoViewHolder(private val binding: ItemTodoBinding) :
        RecyclerView.ViewHolder(binding.root) {

        init {
            binding.root.setOnClickListener {
                onClick(getItem(bindingAdapterPosition).id)
            }
            binding.checkIcon.setOnClickListener {
                onToggle(getItem(bindingAdapterPosition).id)
            }
        }

        fun bind(todo: Todo) {
            binding.titleText.text = todo.title
            binding.checkIcon.alpha = if (todo.isCompleted) 1f else 0.3f
        }
    }

    companion object {
        val DIFF = object : DiffUtil.ItemCallback<Todo>() {
            override fun areItemsTheSame(old: Todo, new: Todo) = old.id == new.id
            override fun areContentsTheSame(old: Todo, new: Todo) = old == new
        }
    }
}
