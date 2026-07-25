import 'package:flutter/material.dart';
import '../models/user_entry.dart';
import '../models/watch_status.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

/// Profil sayfasi: avatar + UserEntry listesinden hesaplanan ozet kartlari.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final profileStats = _ProfileStats.fromEntries(StorageService.getAll());

    final stats = [
      (
        label: 'Toplam Film',
        value: '${profileStats.totalMovies}',
        icon: Icons.movie_outlined
      ),
      (
        label: 'Toplam Dizi',
        value: '${profileStats.totalSeries}',
        icon: Icons.live_tv_outlined
      ),
      (
        label: 'Favoriler',
        value: '${profileStats.totalFavorites}',
        icon: Icons.favorite_border_rounded
      ),
      (
        label: 'Ortalama Puan',
        value: profileStats.averageRatingText,
        icon: Icons.star_border_rounded
      ),
      (
        label: 'Tamamlananlar',
        value: '${profileStats.completed}',
        icon: Icons.check_circle_outline_rounded
      ),
      (
        label: 'İzleniyor',
        value: '${profileStats.watching}',
        icon: Icons.play_circle_outline_rounded
      ),
      (
        label: 'İzlenecekler',
        value: '${profileStats.watchlist}',
        icon: Icons.bookmark_border_rounded
      ),
      (
        label: 'Tekrar İzlenecekler',
        value: '${profileStats.rewatch}',
        icon: Icons.replay_rounded
      ),
      (
        label: 'Bırakılanlar',
        value: '${profileStats.dropped}',
        icon: Icons.cancel_outlined
      ),
      (
        label: 'En sevilen tür',
        value: profileStats.topGenre,
        icon: Icons.category_outlined
      ),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: primary.withValues(alpha: 0.15),
                  child: Icon(Icons.person_rounded, size: 44, color: primary),
                ),
                const SizedBox(height: 14),
                Text('Sinefil',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Film ve dizi arşivin',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 28),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: stats
                .map((stat) => _StatCard(
                      label: stat.label,
                      value: stat.value,
                      icon: stat.icon,
                      primary: primary,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats {
  final int totalMovies;
  final int totalSeries;
  final int totalFavorites;
  final double averageRating;
  final int completed;
  final int watching;
  final int watchlist;
  final int rewatch;
  final int dropped;
  final String topGenre;

  const _ProfileStats({
    required this.totalMovies,
    required this.totalSeries,
    required this.totalFavorites,
    required this.averageRating,
    required this.completed,
    required this.watching,
    required this.watchlist,
    required this.rewatch,
    required this.dropped,
    required this.topGenre,
  });

  String get averageRatingText =>
      averageRating > 0 ? averageRating.toStringAsFixed(1) : '-';

  factory _ProfileStats.fromEntries(List<UserEntry> entries) {
    final rated = entries.where((entry) => entry.userRating > 0).toList();
    final genreCounts = <String, int>{};

    for (final entry in entries) {
      final genre = entry.genre.trim();
      if (genre.isEmpty) continue;
      genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
    }

    return _ProfileStats(
      totalMovies: entries.where((entry) => entry.mediaType == 'movie').length,
      totalSeries: entries.where((entry) => entry.mediaType == 'tv').length,
      totalFavorites: entries.where((entry) => entry.favorite).length,
      averageRating: rated.isEmpty
          ? 0
          : rated.map((entry) => entry.userRating).reduce((a, b) => a + b) /
              rated.length,
      completed: entries
          .where((entry) => entry.status == WatchStatus.completed)
          .length,
      watching:
          entries.where((entry) => entry.status == WatchStatus.watching).length,
      watchlist: entries
          .where((entry) => entry.status == WatchStatus.watchlist)
          .length,
      rewatch:
          entries.where((entry) => entry.status == WatchStatus.rewatch).length,
      dropped:
          entries.where((entry) => entry.status == WatchStatus.dropped).length,
      topGenre: genreCounts.isEmpty
          ? '-'
          : genreCounts.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color primary;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
