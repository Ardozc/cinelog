import 'package:flutter/material.dart';
import '../data/genre_stats.dart';

/// "Tüm Türleri Gör" ile acilan detay sayfasi: kullanicinin listesindeki
/// TUM turler, en cok izlenenden en aza dogru siralanmis olarak gosterilir.
class GenreDetailScreen extends StatelessWidget {
  final Map<String, int> distribution;

  const GenreDetailScreen({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final stats = allGenreStats(distribution);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüm Türler'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: stats.isEmpty
            ? Center(
                child: Text('Henüz veri yok',
                    style: Theme.of(context).textTheme.bodyMedium),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: stats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _GenreDetailTile(rank: index + 1, stat: stats[index]),
              ),
      ),
    );
  }
}

class _GenreDetailTile extends StatelessWidget {
  final int rank;
  final GenreStat stat;

  const _GenreDetailTile({required this.rank, required this.stat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$rank', style: Theme.of(context).textTheme.bodyMedium),
          ),
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration:
                BoxDecoration(color: stat.color, shape: BoxShape.circle),
          ),
          Expanded(
            flex: 3,
            child: Text(
              stat.name,
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (stat.percent / 100).clamp(0, 1),
                minHeight: 6,
                backgroundColor: stat.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(stat.color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 66,
            child: Text(
              '${stat.count}  ${stat.percentLabel}',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
