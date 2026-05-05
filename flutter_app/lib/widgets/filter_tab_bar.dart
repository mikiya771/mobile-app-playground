import 'package:flutter/material.dart';

class FilterTabBar extends StatelessWidget {
  const FilterTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _FilterChipButton(label: 'すべて', isSelected: true)),
          const SizedBox(width: 8),
          Expanded(child: _FilterChipButton(label: '未完了', isSelected: false)),
          const SizedBox(width: 8),
          Expanded(child: _FilterChipButton(label: '完了', isSelected: false)),
        ],
      ),
    );
  }
}

// FilterTabBar 専用の内部ウィジェット（_ プレフィックスでファイル外から隠す）
class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
