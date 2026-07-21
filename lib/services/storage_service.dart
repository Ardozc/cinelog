import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_entry.dart';
import '../models/watch_status.dart';

/// Kullanicinin kisisel listesini (puan, not, durum) cihazda saklar.
/// Hive kullanildigi icin kod uretimi (build_runner) gerekmez;
/// veriler duz Map olarak kutuya yazilir.
class StorageService {
  StorageService._();

  static const String _boxName = 'user_entries';

  static Box get _box => Hive.box(_boxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static List<UserEntry> getAll() {
    return _box.values
        .map((e) => UserEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  static UserEntry? get(int movieId) {
    final raw = _box.get(movieId.toString());
    if (raw == null) return null;
    return UserEntry.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  static Future<void> save(UserEntry entry) async {
    await _box.put(entry.movieId.toString(), entry.toMap());
  }

  static Future<void> delete(int movieId) async {
    await _box.delete(movieId.toString());
  }

  static Future<void> toggleFavorite(int movieId) async {
    final entry = get(movieId);
    if (entry == null) return;
    await save(entry.copyWith(favorite: !entry.favorite));
  }

  static List<UserEntry> byCategory(String category) {
    final all = getAll();
    if (category == 'Hepsi') return all;
    if (category == 'Film') {
      return all.where((e) => e.mediaType == 'movie').toList();
    }
    if (category == 'Dizi') {
      return all.where((e) => e.mediaType == 'tv').toList();
    }
    return all.where((e) => e.genre == category).toList();
  }

  // ---- Istatistik yardimcilari ----

  static int get totalMovies =>
      getAll().where((e) => e.mediaType == 'movie').length;
  static int get totalSeries =>
      getAll().where((e) => e.mediaType == 'tv').length;
  static int get totalFavorites => getAll().where((e) => e.favorite).length;

  static double get averageRating {
    final rated = getAll().where((e) => e.userRating > 0).toList();
    if (rated.isEmpty) return 0;
    return rated.map((e) => e.userRating).reduce((a, b) => a + b) /
        rated.length;
  }

  static double get highestRating {
    final rated = getAll().where((e) => e.userRating > 0).toList();
    if (rated.isEmpty) return 0;
    return rated.map((e) => e.userRating).reduce((a, b) => a > b ? a : b);
  }

  static String get topGenre {
    final counts = <String, int>{};
    for (final e in getAll()) {
      counts[e.genre] = (counts[e.genre] ?? 0) + 1;
    }
    if (counts.isEmpty) return '—';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Toplam izleme suresi (dakika) - basit tahmin: film ~110 dk, dizi bolumu ~45 dk
  static int get totalWatchMinutes {
    final completed = getAll().where((e) => e.status == WatchStatus.completed);
    var total = 0;
    for (final e in completed) {
      total += e.mediaType == 'tv' ? 45 : 110;
    }
    return total;
  }

  static Map<String, int> get genreDistribution {
    final counts = <String, int>{};
    for (final e in getAll()) {
      counts[e.genre] = (counts[e.genre] ?? 0) + 1;
    }
    return counts;
  }

  /// Son 6 ay icin ay basina tamamlanan yapim sayisi
  static Map<String, int> get monthlyCompleted {
    final now = DateTime.now();
    final months =
        List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));
    final labels = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    final result = <String, int>{
      for (final m in months) labels[m.month - 1]: 0
    };
    for (final e in getAll()) {
      final d = e.watchedDate;
      if (d == null || e.status != WatchStatus.completed) continue;
      for (final m in months) {
        if (d.year == m.year && d.month == m.month) {
          result[labels[m.month - 1]] = (result[labels[m.month - 1]] ?? 0) + 1;
        }
      }
    }
    return result;
  }

  /// Son 7 gun icin gunluk aktivite (izleme alışkanlığı grafiği)
  static Map<String, int> get weeklyActivity {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final result = <String, int>{
      for (final d in days) labels[d.weekday - 1]: 0
    };
    for (final e in getAll()) {
      final d = e.watchedDate;
      if (d == null) continue;
      for (final day in days) {
        if (d.year == day.year && d.month == day.month && d.day == day.day) {
          result[labels[day.weekday - 1]] =
              (result[labels[day.weekday - 1]] ?? 0) + 1;
        }
      }
    }
    return result;
  }
}
