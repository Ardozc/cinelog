import 'watch_status.dart';

/// Kullanicinin listesine ekledigi bir yapim icin kaydettigi kisisel veri.
/// TMDb API'sinden gelen bilgiyle kullanicinin kendi puan/not/durum bilgisi
/// birlestirilir. Hive box icinde Map<String,dynamic> olarak saklanir.
class UserEntry {
  final int movieId;
  final String title;
  final String? posterPath;
  final String mediaType; // movie | tv
  final String genre; // baskin tur - kategori filtresi ve istatistik icin
  final double userRating; // 0-10
  final String note;
  final WatchStatus status;
  final DateTime? watchedDate;
  final bool favorite;
  final DateTime addedAt;

  UserEntry({
    required this.movieId,
    required this.title,
    this.posterPath,
    required this.mediaType,
    this.genre = 'Diğer',
    this.userRating = 0,
    this.note = '',
    this.status = WatchStatus.watchlist,
    this.watchedDate,
    this.favorite = false,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  UserEntry copyWith({
    double? userRating,
    String? note,
    WatchStatus? status,
    DateTime? watchedDate,
    bool? favorite,
  }) {
    return UserEntry(
      movieId: movieId,
      title: title,
      posterPath: posterPath,
      mediaType: mediaType,
      genre: genre,
      userRating: userRating ?? this.userRating,
      note: note ?? this.note,
      status: status ?? this.status,
      watchedDate: watchedDate ?? this.watchedDate,
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
        'userRating': userRating,
        'note': note,
        'status': status.name,
        'watchedDate': watchedDate?.toIso8601String(),
        'favorite': favorite,
        'addedAt': addedAt.toIso8601String(),
      };

  factory UserEntry.fromMap(Map map) => UserEntry(
        movieId: map['movieId'],
        title: map['title'],
        posterPath: map['posterPath'],
        mediaType: map['mediaType'] ?? 'movie',
        genre: map['genre'] ?? 'Diğer',
        userRating: (map['userRating'] ?? 0).toDouble(),
        note: map['note'] ?? '',
        status: WatchStatusX.fromName(map['status'] ?? 'watchlist'),
        watchedDate: map['watchedDate'] != null
            ? DateTime.tryParse(map['watchedDate'])
            : null,
        favorite: map['favorite'] ?? false,
        addedAt: map['addedAt'] != null
            ? DateTime.tryParse(map['addedAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}
