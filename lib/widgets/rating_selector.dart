import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 1-10 arasi modern puan secici. Klasik yildizlar yerine
/// buyuk merkezi rakam + yatay dokunulabilir noktalar kullanir.
class RatingSelector extends StatelessWidget {
  final double value; // 0-10
  final ValueChanged<double> onChanged;

  const RatingSelector(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                value == 0 ? '—' : value.toStringAsFixed(0),
                key: ValueKey(value),
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(color: primary),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child:
                  Text('/ 10', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(10, (i) {
            final v = (i + 1).toDouble();
            final filled = v <= value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v == value ? 0 : v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: filled ? 34 : 22,
                  decoration: BoxDecoration(
                    color: filled ? primary : primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
