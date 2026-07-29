import 'package:flutter/material.dart';
import '../data/sort_options.dart';
import '../theme/app_colors.dart';

/// Ana sayfa/favoriler ust cubugunda gosterilen siralama butonu.
/// Dokunuldugunda mevcut secenegi isaretleyen bir bottom sheet acar.
class SortButton extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const SortButton({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final isActive = value != sortOptions.first;

    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive
              ? primary.withValues(alpha: 0.14)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? primary.withValues(alpha: 0.4)
                : Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 18,
              color: isActive
                  ? primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 6),
            Text(
              'Sırala',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.75;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Sırala',
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final option in sortOptions)
                        ListTile(
                          title: Text(option),
                          trailing: option == value
                              ? Icon(Icons.check_rounded, color: primary)
                              : null,
                          onTap: () {
                            onChanged(option);
                            Navigator.pop(sheetContext);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
