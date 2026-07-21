import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  /// Kategoriye gore populer / trend listesi getirir.
  /// category: all | movie | tv
  static Future<List<Movie>> discover({String category = 'all'}) async {
    final path = category == 'tv'
        ? '/tv/popular'
        : category == 'movie'
            ? '/movie/popular'
            : '/trending/all/week';
    final res = await http.get(_uri(path));
    if (res.statusCode != 200) {
      throw Exception('TMDb kesif hatasi: ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return (data['results'] as List).map((e) {
      // trending/all endpoint'i media_type icerir, popular endpoint'leri icermez.
      final withType = category == 'all' ? e : {...e, 'media_type': category};
      return Movie.fromSearchJson(withType);
    }).toList();
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
