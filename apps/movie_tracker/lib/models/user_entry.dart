import 'watch_status.dart';

/// Kullanicinin listesine ekledigi bir yapim icin kaydettigi kisisel veri.
/// TMDb API'sinden gelen bilgiyle kullanicinin kendi puan/not/durum bilgisi
/// birlestirilir. Supabase'deki `entries` tablosunun bir satirina karsilik
/// gelir; toMap/fromMap anahtarlari o tablonun sutun adlarina (snake_case)
/// birebir eslenir.
class UserEntry {
  final int movieId;
  final String title;
  final String? posterPath;
  final String mediaType; // movie | tv
  final String genre; // baskin tur - kart etiketi ve istatistik icin
  final List<String>
      genres; // TMDb'deki tum turler - coklu tur filtrelemesi icin
  final String releaseDate; // TMDb'den gelen cikis tarihi - siralama icin
  final double tmdbRating; // TMDb'den gelen puan - siralama icin
  final double userRating; // 0-10
  final String note;
  final WatchStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? droppedAt;
  final bool favorite;
  final DateTime addedAt;

  UserEntry({
    required this.movieId,
    required this.title,
    this.posterPath,
    required this.mediaType,
    this.genre = 'Diğer',
    this.genres = const [],
    this.releaseDate = '',
    this.tmdbRating = 0,
    this.userRating = 0,
    this.note = '',
    this.status = WatchStatus.watchlist,
    this.startedAt,
    this.completedAt,
    this.droppedAt,
    this.favorite = false,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  /// Kullanicinin mevcut izleme durumuna karsilik gelen tarih; haftalik
  /// aktivite grafiginde kullanilir.
  DateTime? get activityDate {
    switch (status) {
      case WatchStatus.watching:
        return startedAt;
      case WatchStatus.completed:
        return completedAt;
      case WatchStatus.dropped:
        return droppedAt;
      case WatchStatus.watchlist:
      case WatchStatus.rewatch:
        return null;
    }
  }

  UserEntry copyWith({
    double? userRating,
    String? note,
    WatchStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? droppedAt,
    bool? favorite,
  }) {
    return UserEntry(
      movieId: movieId,
      title: title,
      posterPath: posterPath,
      mediaType: mediaType,
      genre: genre,
      genres: genres,
      releaseDate: releaseDate,
      tmdbRating: tmdbRating,
      userRating: userRating ?? this.userRating,
      note: note ?? this.note,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      droppedAt: droppedAt ?? this.droppedAt,
      favorite: favorite ?? this.favorite,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'movie_id': movieId,
        'title': title,
        'poster_path': posterPath,
        'media_type': mediaType,
        'genre': genre,
        'genres': genres,
        'release_date': releaseDate,
        'tmdb_rating': tmdbRating,
        'user_rating': userRating,
        'note': note,
        'status': status.name,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'dropped_at': droppedAt?.toIso8601String(),
        'favorite': favorite,
        'added_at': addedAt.toIso8601String(),
      };

  factory UserEntry.fromMap(Map map) => UserEntry(
        movieId: map['movie_id'],
        title: map['title'],
        posterPath: map['poster_path'],
        mediaType: map['media_type'] ?? 'movie',
        genre: map['genre'] ?? 'Diğer',
        genres: map['genres'] != null
            ? List<String>.from(map['genres'] as List)
            : [if (map['genre'] != null) map['genre'].toString()],
        releaseDate: map['release_date'] ?? '',
        tmdbRating: (map['tmdb_rating'] ?? 0).toDouble(),
        userRating: (map['user_rating'] ?? 0).toDouble(),
        note: map['note'] ?? '',
        status: WatchStatusX.fromName(map['status'] ?? 'watchlist'),
        startedAt: map['started_at'] != null
            ? DateTime.tryParse(map['started_at'])
            : null,
        completedAt: map['completed_at'] != null
            ? DateTime.tryParse(map['completed_at'])
            : null,
        droppedAt: map['dropped_at'] != null
            ? DateTime.tryParse(map['dropped_at'])
            : null,
        favorite: map['favorite'] ?? false,
        addedAt: map['added_at'] != null
            ? DateTime.tryParse(map['added_at']) ?? DateTime.now()
            : DateTime.now(),
      );
}
