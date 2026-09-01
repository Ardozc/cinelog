import 'package:flutter/material.dart';
import '../data/genres.dart';
import '../models/watch_status.dart';
import '../theme/app_colors.dart';
import 'category_chip.dart';

/// Ana sayfa/favoriler ust cubugunda gosterilen filtre butonu. Dokunuldugunda
/// kategori (tek secim), tur (coklu secim) ve izleme durumu (coklu secim)
/// filtrelerini bir arada barindiran bir bottom sheet acar. Herhangi bir
/// secim varsayilandan farkliysa (Hepsi disinda) buton vurgulu gorunur.
class FilterButton extends StatelessWidget {
  final String category;
  final Set<String> selectedGenres;
  final Set<WatchStatus> selectedStatuses;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<Set<String>> onGenresChanged;
  final ValueChanged<Set<WatchStatus>> onStatusesChanged;

  const FilterButton({
    super.key,
    required this.category,
    required this.selectedGenres,
    required this.selectedStatuses,
    required this.onCategoryChanged,
    required this.onGenresChanged,
    required this.onStatusesChanged,
  });

  bool get _isActive =>
      category != 'Hepsi' ||
      selectedGenres.isNotEmpty ||
      selectedStatuses.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final active = _isActive;

    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active
              ? primary.withValues(alpha: 0.14)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? primary.withValues(alpha: 0.4)
                : Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: active
                  ? primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 6),
            Text(
              'Filtrele',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: active
                        ? primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheetContent(
        category: category,
        selectedGenres: selectedGenres,
        selectedStatuses: selectedStatuses,
        onCategoryChanged: onCategoryChanged,
        onGenresChanged: onGenresChanged,
        onStatusesChanged: onStatusesChanged,
      ),
    );
  }
}

class _FilterSheetContent extends StatefulWidget {
  final String category;
  final Set<String> selectedGenres;
  final Set<WatchStatus> selectedStatuses;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<Set<String>> onGenresChanged;
  final ValueChanged<Set<WatchStatus>> onStatusesChanged;

  const _FilterSheetContent({
    required this.category,
    required this.selectedGenres,
    required this.selectedStatuses,
    required this.onCategoryChanged,
    required this.onGenresChanged,
    required this.onStatusesChanged,
  });

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  static const _categories = ['Hepsi', 'Film', 'Dizi'];

  late String _category;
  late Set<String> _genres;
  late Set<WatchStatus> _statuses;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
    _genres = Set.from(widget.selectedGenres);
    _statuses = Set.from(widget.selectedStatuses);
  }

  bool get _hasActiveFilters =>
      _category != 'Hepsi' || _genres.isNotEmpty || _statuses.isNotEmpty;

  void _clearAll() {
    setState(() {
      _category = 'Hepsi';
      _genres = {};
      _statuses = {};
    });
    widget.onCategoryChanged('Hepsi');
    widget.onGenresChanged(const {});
    widget.onStatusesChanged(const {});
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Filtrele',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  if (_hasActiveFilters)
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Temizle'),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Kategori'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in _categories)
                          CategoryChip(
                            label: c,
                            selected: _category == c,
                            onTap: () {
                              setState(() => _category = c);
                              widget.onCategoryChanged(c);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('Tür'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        CategoryChip(
                          label: 'Hepsi',
                          selected: _genres.isEmpty,
                          onTap: () {
                            setState(() => _genres = {});
                            widget.onGenresChanged(const {});
                          },
                        ),
                        for (final genre in GenreCatalog.all)
                          CategoryChip(
                            label: genre,
                            selected: _genres.contains(genre),
                            onTap: () {
                              setState(() {
                                final next = Set<String>.from(_genres);
                                next.contains(genre)
                                    ? next.remove(genre)
                                    : next.add(genre);
                                _genres = next;
                              });
                              widget.onGenresChanged(_genres);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('İzleme Durumu'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        CategoryChip(
                          label: 'Hepsi',
                          selected: _statuses.isEmpty,
                          onTap: () {
                            setState(() => _statuses = {});
                            widget.onStatusesChanged(const {});
                          },
                        ),
                        for (final status in WatchStatus.values)
                          CategoryChip(
                            label: status.label,
                            selected: _statuses.contains(status),
                            onTap: () {
                              setState(() {
                                final next = Set<WatchStatus>.from(_statuses);
                                next.contains(status)
                                    ? next.remove(status)
                                    : next.add(status);
                                _statuses = next;
                              });
                              widget.onStatusesChanged(_statuses);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}
