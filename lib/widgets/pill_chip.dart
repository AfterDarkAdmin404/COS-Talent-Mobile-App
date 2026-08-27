import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A selectable pill — matches the `rounded-full` chip pattern used for
/// the category filters on the web app's `/talent-marketplace` page.
class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  const PillChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.white : AppColors.muted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small static status badge (approved/pending/draft/rejected).
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
