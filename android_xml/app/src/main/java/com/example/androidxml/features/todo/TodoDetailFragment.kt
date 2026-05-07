package com.example.androidxml.features.todo

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.navigation.fragment.navArgs
import com.example.androidxml.databinding.FragmentTodoDetailBinding

class TodoDetailFragment : Fragment() {
    private var _binding: FragmentTodoDetailBinding? = null
    private val binding get() = _binding!!
    private val viewModel: TodoListViewModel by activityViewModels()
    private val args: TodoDetailFragmentArgs by navArgs()

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentTodoDetailBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        viewModel.filtered.observe(viewLifecycleOwner) { todos ->
            val todo = todos.find { it.id == args.todoId } ?: return@observe
            binding.detailTitle.text = todo.title
            binding.detailDescription.text = todo.description.ifBlank { "説明なし" }
            binding.detailPriority.text = "優先度: ${todo.priority.label}"
            binding.detailStatus.text = if (todo.isCompleted) "完了済み" else "未完了"
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
