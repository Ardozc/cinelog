/// TMDb aramasindan / detayindan donen film-dizi modeli.
class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final String releaseDate;
  final double voteAverage;
  final List<String> genres;
  final String mediaType; // 'movie' | 'tv'
  final int? runtimeMinutes;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview = '',
    this.releaseDate = '',
    this.voteAverage = 0,
    this.genres = const [],
    this.mediaType = 'movie',
    this.runtimeMinutes,
  });

  factory Movie.fromSearchJson(Map<String, dynamic> json) {
    final type = json['media_type'] ?? (json['title'] != null ? 'movie' : 'tv');
    return Movie(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'Bilinmiyor',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      mediaType: type == 'movie' || type == 'tv' ? type : 'movie',
    );
  }

  factory Movie.fromDetailJson(Map<String, dynamic> json, String mediaType) {
    final genresJson = (json['genres'] as List?) ?? [];
    return Movie(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'Bilinmiyor',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      genres: genresJson.map((g) => g['name'].toString()).toList(),
      mediaType: mediaType,
      runtimeMinutes: json['runtime'] ??
          ((json['episode_run_time'] as List?)?.isNotEmpty == true
              ? json['episode_run_time'][0]
              : null),
    );
  }

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : '';

  String get year =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '—';

  String get typeLabel => mediaType == 'tv' ? 'Dizi' : 'Film';
}
