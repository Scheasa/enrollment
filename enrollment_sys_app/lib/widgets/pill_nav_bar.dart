import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class PillNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const PillNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Floating bottom bar. The selected item grows into a blue pill with its label.
class PillNavBar extends StatelessWidget {
  final int index;
  final List<PillNavItem> items;
  final ValueChanged<int> onSelected;

  const PillNavBar({
    super.key,
    required this.index,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [for (var i = 0; i < items.length; i++) _item(i)],
        ),
      ),
    );
  }

  Widget _item(int i) {
    final item = items[i];
    final selected = i == index;

    return InkWell(
      customBorder: const StadiumBorder(),
      onTap: () => onSelected(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 18 : 12,
          vertical: 10,
        ),
        decoration: ShapeDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              color: selected ? Colors.white : AppColors.muted,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
