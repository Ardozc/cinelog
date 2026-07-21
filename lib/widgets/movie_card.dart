import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/user_entry.dart';
import '../theme/app_colors.dart';
import '../models/watch_status.dart';

/// Ana sayfa listesindeki her satir icin ~140px yukseklikte modern kart.
/// Basinca hafif buyume (scale) animasyonu icerir.
class MovieCard extends StatefulWidget {
  final UserEntry entry;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onMenuTap;

  const MovieCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onMenuTap,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  double _scale = 1;

  void _setScale(double s) => setState(() => _scale = s);

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setScale(0.97),
      onTapUp: (_) => _setScale(1),
      onTapCancel: () => _setScale(1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(20)),
                child: SizedBox(
                  width: 96,
                  child: e.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: e.posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: primary.withValues(alpha: 0.08)),
                          errorWidget: (_, __, ___) =>
                              Container(color: primary.withValues(alpha: 0.08)),
                        )
                      : Container(
                          color: primary.withValues(alpha: 0.08),
                          child: Icon(Icons.movie_outlined, color: primary),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onFavoriteToggle,
                            child: Icon(
                              e.favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 20,
                              color: e.favorite
                                  ? AppColors.accent
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onMenuTap,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.more_vert_rounded, size: 20),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${e.mediaType == 'tv' ? 'Dizi' : 'Film'} · ${e.genre}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Row(
                        children: [
                          if (e.userRating > 0) ...[
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(e.userRating.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(width: 10),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: e.status.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              e.status.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: e.status.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
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
      ),
    );
  }
}
