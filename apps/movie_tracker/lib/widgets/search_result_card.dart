import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';

/// Arama sonuclarinda gosterilen kart: poster, ad, yil, tur, TMDb puani.
class SearchResultCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool isAdded;

  const SearchResultCard({
    super.key,
    required this.movie,
    required this.onTap,
    required this.onAdd,
    required this.isAdded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(18)),
              child: SizedBox(
                width: 80,
                child: movie.posterUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: movie.posterUrl, fit: BoxFit.cover)
                    : Container(
                        color: primary.withValues(alpha: 0.08),
                        child: Icon(Icons.movie_outlined, color: primary)),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('${movie.typeLabel} · ${movie.year}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 15, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(movie.voteAverage.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.labelLarge),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: IconButton(
                  tooltip: isAdded ? 'Listede' : 'Listeye ekle',
                  onPressed: isAdded ? null : onAdd,
                  icon: Icon(isAdded
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded),
                  color: isAdded ? AppColors.statusCompleted : primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
