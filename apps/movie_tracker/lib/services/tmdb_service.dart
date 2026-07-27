import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/genres.dart';
import '../models/movie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Sayfalanmis bir TMDb liste sonucu (trending veya discover).
/// [hasMore], TMDb'nin donduğu 'page' / 'total_pages' alanlarindan turetilir.
class DiscoverPage {
  final List<Movie> movies;
  final bool hasMore;

  const DiscoverPage({required this.movies, required this.hasMore});

  static const empty = DiscoverPage(movies: [], hasMore: false);
}

/// TMDb (The Movie Database) API entegrasyonu.
///
/// KULLANIM ICIN: https://www.themoviedb.org/settings/api adresinden
/// ucretsiz bir "API Read Access Token" veya "API Key (v3 auth)" alip
/// asagidaki [_apiKey] alanina yapistirin.
class TmdbService {
  TmdbService._();

  static final String _apiKey = dotenv.env['TMDB_API_KEY']!;
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static Map<String, String> get _defaultParams => {
        'api_key': _apiKey,
        'language': 'tr-TR',
      };

  static Uri _uri(String path, [Map<String, String>? extra]) {
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: {..._defaultParams, ...?extra},
    );
  }

  /// Film + dizi + kisi sonuclarini birlikte arar, sadece film/dizi doner.
  static Future<List<Movie>> searchMulti(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await http.get(_uri('/search/multi', {'query': query}));
    if (res.statusCode != 200) {
      throw Exception('TMDb arama hatasi: ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final results = (data['results'] as List)
        .where((e) => e['media_type'] == 'movie' || e['media_type'] == 'tv')
        .map((e) => Movie.fromSearchJson(e))
        .toList();
    return results;
  }

  /// Sayfalanmis bir TMDb liste uc noktasini (trending veya discover) cagirir.
  /// 'popular'/'trending' gibi bazi uc noktalar sonuclarda 'media_type'
  /// alanini icermez; bu durumda [mediaTypeOverride] ile elle eklenir.
  static Future<DiscoverPage> _fetchPage(
    String path, {
    required int page,
    Map<String, String>? extraParams,
    String? mediaTypeOverride,
  }) async {
    final res = await http.get(_uri(path, {
      'page': '$page',
      ...?extraParams,
    }));
    if (res.statusCode != 200) {
      throw Exception('TMDb kesif hatasi: ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final movies = (data['results'] as List).map((e) {
      final withType = mediaTypeOverride == null
          ? e
          : <String, dynamic>{...e, 'media_type': mediaTypeOverride};
      return Movie.fromSearchJson(withType);
    }).toList();
    final totalPages = (data['total_pages'] as int?) ?? page;
    return DiscoverPage(movies: movies, hasMore: page < totalPages);
  }

  /// Secili medya tipi (Hepsi/Film/Dizi) ve tur(ler)e gore populer/trend
  /// icerikleri sayfali olarak getirir.
  ///
  /// Tur secilmemisse ("Hepsi") TMDb'nin kendi sıralamasıyla haftalik trend
  /// listeleri kullanilir (trending/all|movie|tv/week).
  ///
  /// Tur seciliyse (Film, Dizi veya Hepsi farketmeksizin) uygun medya
  /// tip(ler)i icin secili her tur ayri bir discover istegiyle (with_genres
  /// + sort_by=popularity.desc) paralel olarak sorgulanir; tum sonuclar tek
  /// listede birlestirilir, ayni icerik tekrarlanmayacak sekilde
  /// deduplike edilir ve karistirilir (shuffle) — boylece kullanicı ayni
  /// siralamayi/turun surekli baskin cikmasini gormez.
  static Future<DiscoverPage> discoverByFilters({
    required String mediaTypeFilter, // Hepsi | Film | Dizi
    required Set<String> genreNames,
    required int page,
  }) async {
    if (genreNames.isEmpty) {
      final path = switch (mediaTypeFilter) {
        'Film' => '/trending/movie/week',
        'Dizi' => '/trending/tv/week',
        _ => '/trending/all/week',
      };
      final mediaTypeOverride = switch (mediaTypeFilter) {
        'Film' => 'movie',
        'Dizi' => 'tv',
        _ => null, // trending/all zaten media_type alanini icerir
      };
      return _fetchPage(path, page: page, mediaTypeOverride: mediaTypeOverride);
    }

    final wantMovie = mediaTypeFilter != 'Dizi';
    final wantTv = mediaTypeFilter != 'Film';

    final requests = <Future<DiscoverPage>>[
      if (wantMovie)
        for (final id in GenreCatalog.idsForNames(genreNames, 'movie'))
          _discoverByGenreId(id, 'movie', page),
      if (wantTv)
        for (final id in GenreCatalog.idsForNames(genreNames, 'tv'))
          _discoverByGenreId(id, 'tv', page),
    ];
    if (requests.isEmpty) return DiscoverPage.empty;

    final pages = await Future.wait(requests);
    final merged = <Movie>[];
    var hasMore = false;
    for (final p in pages) {
      merged.addAll(p.movies);
      hasMore = hasMore || p.hasMore;
    }
    merged.shuffle();

    final seen = <String>{};
    final deduped =
        merged.where((m) => seen.add('${m.mediaType}-${m.id}')).toList();

    return DiscoverPage(movies: deduped, hasMore: hasMore);
  }

  static Future<DiscoverPage> _discoverByGenreId(
      int genreId, String mediaType, int page) {
    final path = mediaType == 'tv' ? '/discover/tv' : '/discover/movie';
    return _fetchPage(
      path,
      page: page,
      mediaTypeOverride: mediaType,
      extraParams: {
        'with_genres': '$genreId',
        'sort_by': 'popularity.desc',
      },
    );
  }

  static Future<Movie> getDetails(int id, String mediaType) async {
    final path = mediaType == 'tv' ? '/tv/$id' : '/movie/$id';
    final res = await http.get(_uri(path));
    if (res.statusCode != 200) {
      throw Exception('TMDb detay hatasi: ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return Movie.fromDetailJson(data, mediaType);
  }
}
