import 'package:flutter/material.dart';
import '../data/genres.dart';
import 'category_chip.dart';

/// Yatay kaydirilabilir, coklu secim destekleyen tur filtresi.
/// "Hepsi" tum turleri temizler (secili turlerden biri secildiginde otomatik
/// olarak kalkar); en az bir tur secildiginde OR mantigiyla filtreleme yapilir.
class GenreFilterChips extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const GenreFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final genres = GenreCatalog.all;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: genres.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i == 0) {
            return CategoryChip(
              label: 'Hepsi',
              selected: selected.isEmpty,
              onTap: () => onChanged(const {}),
            );
          }
          final genre = genres[i - 1];
          final isSelected = selected.contains(genre);
          return CategoryChip(
            label: genre,
            selected: isSelected,
            onTap: () {
              final next = Set<String>.from(selected);
              isSelected ? next.remove(genre) : next.add(genre);
              onChanged(next);
            },
          );
        },
      ),
    );
  }
}
