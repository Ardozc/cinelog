import 'package:flutter/material.dart';
import '../models/user_entry.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/movie_card.dart';
import 'detail_screen.dart';

/// Kullanıcının favori olarak işaretlediği film ve dizileri listeler.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _searchController = TextEditingController();
  String _filter = 'Tümü';

  static const _filters = ['Tümü', 'Filmler', 'Diziler'];

  List<UserEntry> get _favorites =>
      StorageService.getAll().where((entry) => entry.favorite).toList();

  List<UserEntry> get _filteredFavorites {
    final query = _searchController.text.trim().toLowerCase();
    return _favorites.where((entry) {
      final matchesQuery =
          query.isEmpty || entry.title.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        'Filmler' => entry.mediaType == 'movie',
        'Diziler' => entry.mediaType == 'tv',
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final favorites = _favorites;
    final filteredFavorites = _filteredFavorites;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Favorilerim',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text(
                      '${favorites.length} Favori İçerik',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 18),
                    _SearchBox(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final label = _filters[index];
                          return CategoryChip(
                            label: label,
                            selected: _filter == label,
                            onTap: () => setState(() => _filter = label),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (favorites.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyFavoritesState(primary: primary),
              )
            else if (filteredFavorites.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NoResultsState(primary: primary),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = filteredFavorites[index];
                      return AnimatedOpacity(
                        duration: Duration(milliseconds: 250 + index * 40),
                        opacity: 1,
                        child: MovieCard(
                          entry: entry,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  movieId: entry.movieId,
                                  mediaType: entry.mediaType,
                                ),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                          onFavoriteToggle: () async {
                            await StorageService.toggleFavorite(entry.movieId);
                            if (mounted) setState(() {});
                          },
                          onMenuTap: () => _showMenu(context, entry),
                        ),
                      );
                    },
                    childCount: filteredFavorites.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, UserEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(
                        movieId: entry.movieId,
                        mediaType: entry.mediaType,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.statusDropped,
                ),
                title: const Text(
                  'Listeden Kaldır',
                  style: TextStyle(color: AppColors.statusDropped),
                ),
                onTap: () async {
                  await StorageService.delete(entry.movieId);
                  if (context.mounted) Navigator.pop(context);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Favorilerde ara...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  final Color primary;

  const _EmptyFavoritesState({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 44,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Henüz favori eklemedin.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Beğendiğin film ve dizileri kalp ikonuna dokunarak favorilerine ekleyebilirsin.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final Color primary;

  const _NoResultsState({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: primary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              'Eşleşen favori bulunamadı',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
