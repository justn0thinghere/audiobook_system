import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SoftChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const SoftChip({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    this.selectedColor = AppColors.primaryBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? selectedColor : AppColors.surface;
    final border = selected ? selectedColor : AppColors.cardBorder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
