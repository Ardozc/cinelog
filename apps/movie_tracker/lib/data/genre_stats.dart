import 'package:flutter/material.dart';
import '../theme/genre_colors.dart';

/// Istatistik ekraninda (donut grafik, ozet liste, detay sayfasi) kullanilan
/// tek bir tur satirinin hazir hali: sayim, yuzde ve sabit renk.
class GenreStat {
  final String name;
  final int count;
  final double percent; // 0-100
  final Color color;
  final bool isOther;

  const GenreStat({
    required this.name,
    required this.count,
    required this.percent,
    required this.color,
    this.isOther = false,
  });

  /// Kucuk yuzdelerde (%1'in altinda) tek ondalik, diger durumlarda
  /// yuvarlanmis tam sayi gosterir (ör. "%24", "%0.5").
  String get percentLabel =>
      percent < 1 ? '%${percent.toStringAsFixed(1)}' : '%${percent.round()}';
}

/// Donut grafik + ozet liste icin: en cok izlenen ilk [topCount] tur
/// gosterilir, geri kalani tek bir "Diğer" diliminde birlestirilir.
const int genreChartTopCount = 6;

List<GenreStat> topGenreStats(
  Map<String, int> distribution, {
  int topCount = genreChartTopCount,
}) {
  final total = distribution.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return [];

  final sorted = distribution.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.take(topCount);
  final otherCount =
      sorted.skip(topCount).fold<int>(0, (sum, e) => sum + e.value);

  return [
    for (final e in top)
      GenreStat(
        name: e.key,
        count: e.value,
        percent: e.value / total * 100,
        color: GenreColors.forGenre(e.key),
      ),
    if (otherCount > 0)
      GenreStat(
        name: 'Diğer',
        count: otherCount,
        percent: otherCount / total * 100,
        color: GenreColors.other,
        isOther: true,
      ),
  ];
}

/// Detay sayfasi icin: TUM turler, en cok izlenenden en aza dogru siralanmis
/// (gruplama yok).
List<GenreStat> allGenreStats(Map<String, int> distribution) {
  final total = distribution.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return [];

  final sorted = distribution.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return [
    for (final e in sorted)
      GenreStat(
        name: e.key,
        count: e.value,
        percent: e.value / total * 100,
        color: GenreColors.forGenre(e.key),
      ),
  ];
}
