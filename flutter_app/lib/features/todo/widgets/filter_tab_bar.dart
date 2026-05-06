import 'package:flutter/material.dart';
import '../todo.dart';

class FilterTabBar extends StatelessWidget {
  const FilterTabBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChange,
  });

  final TodoFilter selectedFilter;
  final void Function(TodoFilter) onFilterChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _FilterChipButton(
              label: 'すべて',
              isSelected: selectedFilter == TodoFilter.all,
              onTap: () => onFilterChange(TodoFilter.all),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterChipButton(
              label: '未完了',
              isSelected: selectedFilter == TodoFilter.active,
              onTap: () => onFilterChange(TodoFilter.active),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterChipButton(
              label: '完了',
              isSelected: selectedFilter == TodoFilter.completed,
              onTap: () => onFilterChange(TodoFilter.completed),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
