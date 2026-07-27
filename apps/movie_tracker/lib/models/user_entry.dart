import 'watch_status.dart';

/// Kullanicinin listesine ekledigi bir yapim icin kaydettigi kisisel veri.
/// TMDb API'sinden gelen bilgiyle kullanicinin kendi puan/not/durum bilgisi
/// birlestirilir. Hive box icinde Map<String,dynamic> olarak saklanir.
class UserEntry {
  final int movieId;
  final String title;
  final String? posterPath;
  final String mediaType; // movie | tv
  final String genre; // baskin tur - kart etiketi ve istatistik icin
  final List<String>
      genres; // TMDb'deki tum turler - coklu tur filtrelemesi icin
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
        'movieId': movieId,
        'title': title,
        'posterPath': posterPath,
        'mediaType': mediaType,
        'genre': genre,
        'genres': genres,
        'userRating': userRating,
        'note': note,
        'status': status.name,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'droppedAt': droppedAt?.toIso8601String(),
        'favorite': favorite,
        'addedAt': addedAt.toIso8601String(),
      };

  factory UserEntry.fromMap(Map map) => UserEntry(
        movieId: map['movieId'],
        title: map['title'],
        posterPath: map['posterPath'],
        mediaType: map['mediaType'] ?? 'movie',
        genre: map['genre'] ?? 'Diğer',
        genres: map['genres'] != null
            ? List<String>.from(map['genres'] as List)
            : [if (map['genre'] != null) map['genre'].toString()],
        userRating: (map['userRating'] ?? 0).toDouble(),
        note: map['note'] ?? '',
        status: WatchStatusX.fromName(map['status'] ?? 'watchlist'),
        startedAt: map['startedAt'] != null
            ? DateTime.tryParse(map['startedAt'])
            : null,
        completedAt: map['completedAt'] != null
            ? DateTime.tryParse(map['completedAt'])
            : null,
        droppedAt: map['droppedAt'] != null
            ? DateTime.tryParse(map['droppedAt'])
            : null,
        favorite: map['favorite'] ?? false,
        addedAt: map['addedAt'] != null
            ? DateTime.tryParse(map['addedAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}
