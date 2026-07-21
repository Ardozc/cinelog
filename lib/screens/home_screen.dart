import 'package:flutter/material.dart';
import '../models/user_entry.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/movie_card.dart';
import 'detail_screen.dart';

/// Ana sayfa: karsilama, arama kutusu, kategori filtreleri ve kullanicinin listesi.
class HomeScreen extends StatefulWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationsTap;

  const HomeScreen({
    super.key,
    required this.onSearchTap,
    required this.onProfileTap,
    required this.onNotificationsTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _category = 'Hepsi';
  final _categories = const ['Hepsi', 'Film', 'Dizi', 'Anime', 'Belgesel'];

  List<UserEntry> get _filtered => StorageService.byCategory(_category);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Merhaba 👋',
                                  style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 2),
                              Text('Ne izlemek istersin?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                            ],
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _IconBadge(
                              icon: Icons.notifications_none_rounded,
                              onTap: widget.onNotificationsTap,
                            ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: widget.onProfileTap,
                          behavior: HitTestBehavior.opaque,
                          child: CircleAvatar(
                            radius: 21,
                            backgroundColor: primary.withValues(alpha: 0.15),
                            child: Icon(Icons.person_rounded, color: primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: widget.onSearchTap,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.25 : 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color),
                            const SizedBox(width: 12),
                            Text('Film veya dizi ara...',
                                style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => CategoryChip(
                          label: _categories[i],
                          selected: _category == _categories[i],
                          onTap: () =>
                              setState(() => _category = _categories[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (_filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(primary: primary),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final entry = _filtered[i];
                      return AnimatedOpacity(
                        duration: Duration(milliseconds: 250 + i * 40),
                        opacity: 1,
                        child: MovieCard(
                          entry: entry,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                    movieId: entry.movieId,
                                    mediaType: entry.mediaType),
                              ),
                            );
                            setState(() {});
                          },
                          onFavoriteToggle: () async {
                            await StorageService.toggleFavorite(entry.movieId);
                            setState(() {});
                          },
                          onMenuTap: () => _showMenu(context, entry),
                        ),
                      );
                    },
                    childCount: _filtered.length,
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                            mediaType: entry.mediaType)),
                  ).then((_) => setState(() {}));
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.statusDropped),
                title: const Text('Listeden Kaldır',
                    style: TextStyle(color: AppColors.statusDropped)),
                onTap: () async {
                  await StorageService.delete(entry.movieId);
                  if (context.mounted) Navigator.pop(context);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBadge({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
            ],
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color primary;
  const _EmptyState({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child:
                  Icon(Icons.movie_filter_outlined, size: 40, color: primary),
            ),
            const SizedBox(height: 20),
            Text('Henüz listen boş',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Sağ alttaki + butonuna dokunarak\nfilm veya dizi aramaya başla.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
