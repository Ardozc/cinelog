import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/user_entry.dart';
import '../models/watch_status.dart';
import '../services/storage_service.dart';
import '../services/tmdb_service.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_selector.dart';
import '../widgets/status_selector.dart';

/// Film / dizi detay sayfasi. TMDb'den detay bilgisini ceker, altta
/// kullanicinin kendi puan / not / durum girisini gosterir.
class DetailScreen extends StatefulWidget {
  final int movieId;
  final String mediaType;
  final Movie? preview; // arama sonucundan gelen on izleme (hizli render icin)

  const DetailScreen(
      {super.key,
      required this.movieId,
      required this.mediaType,
      this.preview});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  Movie? _movie;
  bool _loading = true;
  String? _error;

  double _rating = 0;
  final _noteController = TextEditingController();
  WatchStatus _status = WatchStatus.watchlist;
  DateTime? _watchedDate;
  bool _favorite = false;
  bool _justAdded = false;

  @override
  void initState() {
    super.initState();
    _movie = widget.preview;
    if (_movie != null) _loading = false;
    _loadExistingEntry();
    _fetchDetails();
  }

  void _loadExistingEntry() {
    final existing = StorageService.get(widget.movieId);
    if (existing != null) {
      _rating = existing.userRating;
      _noteController.text = existing.note;
      _status = existing.status;
      _watchedDate = existing.watchedDate;
      _favorite = existing.favorite;
    }
  }

  Future<void> _fetchDetails() async {
    try {
      final movie =
          await TmdbService.getDetails(widget.movieId, widget.mediaType);
      if (!mounted) return;
      setState(() {
        _movie = movie;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = _movie == null;
        _error = _movie == null
            ? 'Detaylar yüklenemedi. TMDb API anahtarını kontrol et.'
            : null;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addToList() async {
    final m = _movie;
    if (m == null) return;
    final entry = UserEntry(
      movieId: m.id,
      title: m.title,
      posterPath: m.posterPath,
      mediaType: m.mediaType,
      genre: m.genres.isNotEmpty ? m.genres.first : 'Diğer',
      userRating: _rating,
      note: _noteController.text,
      status: _status,
      watchedDate: _watchedDate,
      favorite: _favorite,
    );
    await StorageService.save(entry);
    setState(() => _justAdded = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    if (_loading) {
      return Scaffold(
          body: Center(child: CircularProgressIndicator(color: primary)));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center))),
      );
    }

    final m = _movie!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context)),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleIconButton(
                  icon: _favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: _favorite ? AppColors.accent : null,
                  onTap: () => setState(() => _favorite = !_favorite),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if ((m.backdropUrl.isNotEmpty ? m.backdropUrl : m.posterUrl)
                      .isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: m.backdropUrl.isNotEmpty
                          ? m.backdropUrl
                          : m.posterUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: primary.withValues(alpha: 0.15)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: 0.95),
                        ],
                        stops: const [0.4, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Tag(text: m.year),
                      if (m.runtimeMinutes != null)
                        _Tag(text: '${m.runtimeMinutes} dk'),
                      for (final g in m.genres.take(3))
                        _Tag(text: g, tinted: true, primary: primary),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 18, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(m.voteAverage.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Özet', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    m.overview.isNotEmpty
                        ? m.overview
                        : 'Bu yapım için özet bulunamadı.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kendi Değerlendirmen',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 18),
                        RatingSelector(
                            value: _rating,
                            onChanged: (v) => setState(() => _rating = v)),
                        const SizedBox(height: 22),
                        Text('Not',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              hintText: 'Bu yapım hakkında düşüncelerin...'),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                                child: Text('İzleme Tarihi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium)),
                            TextButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _watchedDate ?? DateTime.now(),
                                  firstDate: DateTime(1990),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _watchedDate = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today_outlined,
                                  size: 16),
                              label: Text(
                                _watchedDate == null
                                    ? 'Seç'
                                    : '${_watchedDate!.day}/${_watchedDate!.month}/${_watchedDate!.year}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('İzleme Durumu',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        StatusSelector(
                            selected: _status,
                            onChanged: (s) => setState(() => _status = s)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addToList,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _justAdded
                    ? const Row(
                        key: ValueKey('added'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('LİSTEYE EKLENDİ'),
                        ],
                      )
                    : const Text('LİSTEME EKLE', key: ValueKey('add')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool tinted;
  final Color? primary;
  const _Tag({required this.text, this.tinted = false, this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tinted
            ? (primary ?? AppColors.primary).withValues(alpha: 0.12)
            : Theme.of(context).dividerColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: tinted
                  ? primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: tinted ? FontWeight.w600 : FontWeight.w500,
            ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const _CircleIconButton(
      {required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
      ),
    );
  }
}
