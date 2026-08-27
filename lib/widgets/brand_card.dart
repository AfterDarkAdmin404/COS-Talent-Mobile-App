import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The card shell used across the app — `rounded-2xl` + `shadow-sm`,
/// matching the web app's card pattern (see `AppRadius.card`).
class BrandCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: brandShadow(strength: 0.6),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: card,
    );
  }
}
