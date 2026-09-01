import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_entry.dart';
import '../models/watch_status.dart';

/// Kullanicinin kisisel listesini (puan, not, durum) Supabase'deki `entries`
/// tablosunda saklar. Oturum acildiginda kullanicinin tum kayitlari tek
/// seferde cekilip bellekte tutulur (eski Hive box'inin yerini alan basit
/// bir onbellek); ekranlar hala senkron okuma yapar (getAll, get, vb.),
/// sadece yazma islemleri (save/delete) arka planda Supabase'e gider.
///
/// Ayni hesabin baska bir cihazda yaptigi degisiklikleri yakalamak icin
/// `entries` tablosuna Supabase Realtime aboneligi aciliyor: baska bir
/// cihaz/oturum bir satir ekler/gunceller/silerse, bu cihaz otomatik olarak
/// listeyi yeniden ceker ve ekranlar `changes` uzerinden anlik guncellenir.
/// NOT: Bunun calismasi icin Supabase Dashboard > Database > Replication
/// altinda `entries` tablosunda Realtime'in acik olmasi gerekiyor.
class StorageService {
  StorageService._();

  static List<UserEntry> _cache = [];

  /// Veri her degistiginde (ekleme/silme/favori) artar. Ekranlar bunu
  /// dinleyerek IndexedStack icinde bile anlik olarak yeniden cizilir.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static RealtimeChannel? _channel;

  static SupabaseClient get _client => Supabase.instance.client;
  static String get _uid => _client.auth.currentUser!.id;

  /// Oturum acildiginda (AuthGate) cagrilir: kullanicinin tum kayitlarini
  /// Supabase'den cekip bellek onbellegini doldurur ve baska cihazlardan
  /// gelecek degisiklikleri dinlemeye baslar.
  static Future<void> loadForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _cache = [];
      changes.value++;
      return;
    }
    await _fetchAndCache(user.id);
    _subscribeToRemoteChanges(user.id);
  }

  /// Oturum kapandiginda (AuthGate) cagrilir: onbellek temizlenir ve
  /// realtime aboneligi kapatilir.
  static void clear() {
    _cache = [];
    changes.value++;
    _unsubscribeFromRemoteChanges();
  }

  static Future<void> _fetchAndCache(String userId) async {
    final rows = await _client.from('entries').select().eq('user_id', userId);
    _cache = (rows as List)
        .map((row) => UserEntry.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
    changes.value++;
  }

  /// `entries` tablosunda bu kullanicinin satirlarinda olan her degisiklikte
  /// (baska bir cihazdan gelen dahil) listeyi tamamen yeniden cekiyoruz.
  /// Tek tek satir yamalamak yerine yeniden cekmeyi tercih etmemizin nedeni:
  /// silme olaylarinda Postgres'in `old` kaydi (REPLICA IDENTITY ayarina
  /// gore) sadece birincil anahtari icerebiliyor, movie_id/media_type
  /// gelmeyebiliyor - tam yeniden cekme bu belirsizligi ortadan kaldiriyor.
  static void _subscribeToRemoteChanges(String userId) {
    _unsubscribeFromRemoteChanges();
    _channel = _client
        .channel('entries-changes-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'entries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _fetchAndCache(userId),
        )
        .subscribe();
  }

  static void _unsubscribeFromRemoteChanges() {
    final channel = _channel;
    if (channel != null) {
      _channel = null;
      _client.removeChannel(channel);
    }
  }

  static List<UserEntry> getAll() {
    final list = List<UserEntry>.from(_cache);
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  static UserEntry? get(int movieId, String mediaType) {
    for (final e in _cache) {
      if (e.movieId == movieId && e.mediaType == mediaType) return e;
    }
    return null;
  }

  static Future<void> save(UserEntry entry) async {
    final row = entry.toMap()..['user_id'] = _uid;
    await _client
        .from('entries')
        .upsert(row, onConflict: 'user_id,movie_id,media_type');
    _cache.removeWhere(
        (e) => e.movieId == entry.movieId && e.mediaType == entry.mediaType);
    _cache.add(entry);
    changes.value++;
  }

  static Future<void> delete(int movieId, String mediaType) async {
    await _client.from('entries').delete().match({
      'user_id': _uid,
      'movie_id': movieId,
      'media_type': mediaType,
    });
    _cache.removeWhere(
        (e) => e.movieId == movieId && e.mediaType == mediaType);
    changes.value++;
  }

  static Future<void> toggleFavorite(int movieId, String mediaType) async {
    final entry = get(movieId, mediaType);
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

  /// Coklu tur filtrelemesi (OR mantigi): secili turlerden herhangi birine
  /// sahip olan icerikler eslesir. Bos kume = filtre yok, tumu eslesir.
  static bool matchesGenres(UserEntry entry, Set<String> selected) =>
      selected.isEmpty || entry.genres.any(selected.contains);

  /// Coklu izleme durumu filtrelemesi (OR mantigi). Bos kume = filtre yok.
  static bool matchesStatuses(UserEntry entry, Set<WatchStatus> selected) =>
      selected.isEmpty || selected.contains(entry.status);

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

  static String topGenre({String? mediaType}) {
    final counts = genreDistribution(mediaType: mediaType);
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

  /// [mediaType] verilirse ('movie'/'tv') sadece o medya tipine ait
  /// kayitlarin tur dagilimini dondurur; null ise tumu (Hepsi) dahil edilir.
  static Map<String, int> genreDistribution({String? mediaType}) {
    final counts = <String, int>{};
    for (final e in getAll()) {
      if (mediaType != null && e.mediaType != mediaType) continue;
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
      final d = e.completedAt;
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
      final d = e.activityDate;
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
