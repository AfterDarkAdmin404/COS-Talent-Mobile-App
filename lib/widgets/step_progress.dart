import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StepProgress extends StatelessWidget {
  final int stepCount;
  final int currentIndex; // 0-based
  final List<String> labels;

  const StepProgress({
    super.key,
    required this.stepCount,
    required this.currentIndex,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(stepCount, (i) {
            final isDone = i < currentIndex;
            final isActive = i == currentIndex;
            final color = isDone || isActive ? AppColors.teal : AppColors.border;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == stepCount - 1 ? 0 : 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          'Step ${currentIndex + 1} of $stepCount · ${labels[currentIndex]}',
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
