import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/user_entry.dart';
import '../services/storage_service.dart';
import '../services/tmdb_service.dart';
import '../theme/app_colors.dart';
import '../widgets/search_result_card.dart';
import 'detail_screen.dart';

/// Kesfet / arama sayfasi. TMDb'de gercek zamanli arama yapar (debounce ile),
/// sonuclari fade-in animasyonuyla listeler.
class SearchScreen extends StatefulWidget {
  final FocusNode? focusNode;

  const SearchScreen({super.key, this.focusNode});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Movie> _results = [];
  Set<int> _savedIds = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshSavedIds(setStateAfterRead: false);
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final results = await TmdbService.searchMulti(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sonuçlar alınamadı. TMDb API anahtarını kontrol et.';
      });
    }
  }

  void _refreshSavedIds({bool setStateAfterRead = true}) {
    final ids = StorageService.getAll().map((entry) => entry.movieId).toSet();
    if (!setStateAfterRead) {
      _savedIds = ids;
      return;
    }
    if (mounted) setState(() => _savedIds = ids);
  }

  Future<void> _openDetail(Movie movie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
            movieId: movie.id, mediaType: movie.mediaType, preview: movie),
      ),
    );
    _refreshSavedIds();
  }

  Future<void> _addResult(Movie movie) async {
    try {
      Movie details = movie;
      try {
        details = await TmdbService.getDetails(movie.id, movie.mediaType);
      } catch (_) {
        details = movie;
      }

      await StorageService.save(
        UserEntry(
          movieId: details.id,
          title: details.title,
          posterPath: details.posterPath,
          mediaType: details.mediaType,
          genre: details.genres.isNotEmpty ? details.genres.first : 'Diğer',
        ),
      );

      _refreshSavedIds();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${details.title} listeye eklendi')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Listeye eklenemedi. Lütfen tekrar dene.')),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keşfet', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              onChanged: _onChanged,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Film veya dizi ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color primary) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge));
    }
    if (_controller.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded,
                size: 48, color: primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Aramaya başla', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
          child: Text('Sonuç bulunamadı',
              style: Theme.of(context).textTheme.bodyLarge));
    }
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 1,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final movie = _results[i];
          return SearchResultCard(
            movie: movie,
            isAdded: _savedIds.contains(movie.id),
            onAdd: () => _addResult(movie),
            onTap: () => _openDetail(movie),
          );
        },
      ),
    );
  }
}
