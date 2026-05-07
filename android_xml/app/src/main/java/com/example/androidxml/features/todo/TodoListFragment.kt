package com.example.androidxml.features.todo

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.ItemTouchHelper
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.example.androidxml.R
import com.example.androidxml.databinding.FragmentTodoListBinding

class TodoListFragment : Fragment() {
    private var _binding: FragmentTodoListBinding? = null
    private val binding get() = _binding!!
    private val viewModel: TodoListViewModel by activityViewModels()

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentTodoListBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        val adapter = TodoAdapter(
            onToggle = { viewModel.toggle(it) },
            onClick = { id ->
                val action = TodoListFragmentDirections.actionListToDetail(id)
                findNavController().navigate(action)
            },
        )
        binding.recyclerView.layoutManager = LinearLayoutManager(requireContext())
        binding.recyclerView.adapter = adapter

        ItemTouchHelper(object : ItemTouchHelper.SimpleCallback(0, ItemTouchHelper.LEFT) {
            override fun onMove(rv: RecyclerView, vh: RecyclerView.ViewHolder, t: RecyclerView.ViewHolder) = false
            override fun onSwiped(vh: RecyclerView.ViewHolder, direction: Int) {
                viewModel.delete(adapter.currentList[vh.bindingAdapterPosition].id)
            }
        }).attachToRecyclerView(binding.recyclerView)

        binding.tabAll.setOnClickListener { viewModel.setFilter(TodoFilter.ALL) }
        binding.tabActive.setOnClickListener { viewModel.setFilter(TodoFilter.ACTIVE) }
        binding.tabCompleted.setOnClickListener { viewModel.setFilter(TodoFilter.COMPLETED) }

        viewModel.filtered.observe(viewLifecycleOwner) { adapter.submitList(it) }
        viewModel.filter.observe(viewLifecycleOwner) { selected ->
            val primary = ContextCompat.getColor(requireContext(), R.color.purple_500)
            val normal = ContextCompat.getColor(requireContext(), android.R.color.darker_gray)
            binding.tabAll.setTextColor(if (selected == TodoFilter.ALL) primary else normal)
            binding.tabActive.setTextColor(if (selected == TodoFilter.ACTIVE) primary else normal)
            binding.tabCompleted.setTextColor(if (selected == TodoFilter.COMPLETED) primary else normal)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
