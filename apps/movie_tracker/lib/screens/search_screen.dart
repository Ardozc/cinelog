import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/user_entry.dart';
import '../services/storage_service.dart';
import '../services/tmdb_service.dart';
import '../theme/app_colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/genre_filter_chips.dart';
import '../widgets/search_result_card.dart';
import 'detail_screen.dart';

/// Kesfet / arama sayfasi. TMDb'de gercek zamanli arama yapar (debounce ile),
/// arama kutusu bosken Netflix benzeri, sonsuz kaydirmali bir "Önerilenler"
/// bolumu gosterir. Hepsi/Film/Dizi ve coklu tur (genre) filtreleri hem
/// onerilere hem de arama sonuclarina uygulanir.
///
/// Onerilenler; tur secilmemisse TMDb'nin haftalik trend listelerinden,
/// tur seciliyse ilgili discover uc noktasindan (populerlige gore) sayfa
/// sayfa yuklenir. Filtre degistiginde sayfalama sifirlanir.
class SearchScreen extends StatefulWidget {
  final FocusNode? focusNode;

  const SearchScreen({super.key, this.focusNode});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  static const _mediaTypes = ['Hepsi', 'Film', 'Dizi'];
  static const _loadMoreThreshold = 400.0;

  String _mediaTypeFilter = 'Hepsi';
  Set<String> _selectedGenres = {};

  List<Movie> _results = [];
  bool _loading = false;
  String? _error;

  List<Movie> _recommended = [];
  final Set<String> _recommendedSeenKeys = {};
  int _recommendedPage = 1;
  bool _hasMoreRecommended = true;
  bool _loadingRecommended = true;
  bool _loadingMoreRecommended = false;
  String? _recommendedError;
  int _recommendedRequestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchRecommended();
  }

  void _onScroll() {
    if (_controller.text.trim().isNotEmpty) {
      return; // sadece oneriler sayfalanir
    }
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _loadMoreRecommended();
    }
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

  /// Mevcut filtrelerle sayfa 1'i sifirdan yukler; onceki liste temizlenir.
  Future<void> _fetchRecommended() async {
    final requestId = ++_recommendedRequestId;
    setState(() {
      _loadingRecommended = true;
      _recommendedError = null;
      _recommended = [];
      _recommendedSeenKeys.clear();
      _recommendedPage = 1;
      _hasMoreRecommended = true;
    });
    try {
      final result = await TmdbService.discoverByFilters(
        mediaTypeFilter: _mediaTypeFilter,
        genreNames: _selectedGenres,
        page: 1,
      );
      if (!mounted || requestId != _recommendedRequestId) return;
      final movies = result.movies
          .where((m) => _recommendedSeenKeys.add('${m.mediaType}-${m.id}'))
          .toList();
      setState(() {
        _recommended = movies;
        _hasMoreRecommended = result.hasMore;
        _loadingRecommended = false;
      });
    } catch (e) {
      if (!mounted || requestId != _recommendedRequestId) return;
      setState(() {
        _loadingRecommended = false;
        _recommendedError =
            'Öneriler alınamadı. TMDb API anahtarını kontrol et.';
      });
    }
  }

  /// Sonsuz kaydirma: listenin sonuna gelindiginde bir sonraki sayfayi ekler.
  Future<void> _loadMoreRecommended() async {
    if (_loadingRecommended || _loadingMoreRecommended) return;
    if (!_hasMoreRecommended) return;

    final requestId = _recommendedRequestId;
    final nextPage = _recommendedPage + 1;
    setState(() => _loadingMoreRecommended = true);
    try {
      final result = await TmdbService.discoverByFilters(
        mediaTypeFilter: _mediaTypeFilter,
        genreNames: _selectedGenres,
        page: nextPage,
      );
      if (!mounted || requestId != _recommendedRequestId) return;
      final newMovies = result.movies
          .where((m) => _recommendedSeenKeys.add('${m.mediaType}-${m.id}'))
          .toList();
      setState(() {
        _recommended = [..._recommended, ...newMovies];
        _recommendedPage = nextPage;
        _hasMoreRecommended = result.hasMore;
        _loadingMoreRecommended = false;
      });
    } catch (e) {
      if (!mounted || requestId != _recommendedRequestId) return;
      setState(() => _loadingMoreRecommended = false);
    }
  }

  void _setMediaTypeFilter(String value) {
    if (value == _mediaTypeFilter) return;
    setState(() => _mediaTypeFilter = value);
    _fetchRecommended();
  }

  void _setSelectedGenres(Set<String> genres) {
    setState(() => _selectedGenres = genres);
    _fetchRecommended();
  }

  /// Arama sonuclarina medya tipi + tur filtresini uygular ve ayni icerigin
  /// (mediaType+id) birden fazla kez listelenmesini engeller. Onerilenler
  /// listesi zaten sunucu tarafinda filtrelenip yuklenirken deduplike edildigi
  /// icin burada yalnizca metin arama sonuclari icin kullanilir.
  List<Movie> _applyFilters(List<Movie> source) {
    final filtered = source.where((m) {
      final matchesType = switch (_mediaTypeFilter) {
        'Film' => m.mediaType == 'movie',
        'Dizi' => m.mediaType == 'tv',
        _ => true,
      };
      final matchesGenre =
          _selectedGenres.isEmpty || m.genres.any(_selectedGenres.contains);
      return matchesType && matchesGenre;
    }).toList();

    final seen = <String>{};
    return filtered.where((m) => seen.add('${m.mediaType}-${m.id}')).toList();
  }

  Future<void> _openDetail(Movie movie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
            movieId: movie.id, mediaType: movie.mediaType, preview: movie),
      ),
    );
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
          genres: details.genres,
          releaseDate: details.releaseDate,
          tmdbRating: details.voteAverage,
        ),
      );

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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => CategoryChip(
                  label: _mediaTypes[i],
                  selected: _mediaTypeFilter == _mediaTypes[i],
                  onTap: () => _setMediaTypeFilter(_mediaTypes[i]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GenreFilterChips(
              selected: _selectedGenres,
              onChanged: _setSelectedGenres,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: StorageService.changes,
                builder: (context, _, __) => _buildBody(primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color primary) {
    final isSearching = _controller.text.trim().isNotEmpty;

    if (isSearching) {
      if (_loading) {
        return Center(child: CircularProgressIndicator(color: primary));
      }
      if (_error != null) {
        return Center(
            child: Text(_error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge));
      }
      final filtered = _applyFilters(_results);
      if (filtered.isEmpty) {
        return Center(
            child: Text('Sonuç bulunamadı',
                style: Theme.of(context).textTheme.bodyLarge));
      }
      return _buildList(filtered, primary, showHeader: false);
    }

    if (_loadingRecommended) {
      return Center(child: CircularProgressIndicator(color: primary));
    }
    if (_recommendedError != null) {
      return Center(
          child: Text(_recommendedError!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge));
    }
    if (_recommended.isEmpty) {
      return Center(
          child: Text('Bu filtreler için öneri bulunamadı',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge));
    }
    return _buildList(
      _recommended,
      primary,
      showHeader: true,
      showLoadingFooter: _loadingMoreRecommended,
    );
  }

  Widget _buildList(
    List<Movie> movies,
    Color primary, {
    required bool showHeader,
    bool showLoadingFooter = false,
  }) {
    final headerOffset = showHeader ? 1 : 0;
    final footerCount = showLoadingFooter ? 1 : 0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 1,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: movies.length + headerOffset + footerCount,
        itemBuilder: (_, i) {
          if (showHeader && i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Önerilenler',
                  style: Theme.of(context).textTheme.titleLarge),
            );
          }
          if (showLoadingFooter && i == movies.length + headerOffset) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: primary)),
            );
          }
          final movie = movies[i - headerOffset];
          return SearchResultCard(
            movie: movie,
            isAdded: StorageService.get(movie.id) != null,
            onAdd: () => _addResult(movie),
            onTap: () => _openDetail(movie),
          );
        },
      ),
    );
  }
}
