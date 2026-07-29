import 'package:flutter/material.dart';
import '../data/genres.dart';

/// Tur bazli sabit renk paleti. Ayni tur adi, uygulamanin her yerinde
/// (donut grafik, ozet liste, "Tum Turler" detay sayfasi) her zaman ayni
/// renkle gosterilir.
class GenreColors {
  GenreColors._();

  /// "Diğer" (gruplanmis kalan turler) icin kullanilan notr gri.
  static const other = Color(0xFF9CA3AF);

  /// 9 belirgin sekilde farkli hue (40° arayla) x 3 ton/doygunluk bandi =
  /// 27 tur icin (TMDb'nin tum kataloglari) collision'suz, ayirt edilebilir
  /// bir renk seti. Sadece hue'ya dayanan tek boyutlu bir yontem (ör. altin
  /// aci) sabit 27 ogeli bir kumede bazi ciftlerin kacinilmaz olarak
  /// birbirine cok yakin dusmesine yol acar (pigeonhole); iki boyutlu bu
  /// yaklasim ardisik (alfabetik olarak yakin) turlerin her zaman farkli
  /// hue diliminde kalmasini garanti eder.
  static const int _hueSlots = 9;
  static const double _hueStep = 360 / _hueSlots;
  static const List<double> _lightness = [0.60, 0.72, 0.82];
  static const List<double> _saturation = [0.68, 0.55, 0.62];

  /// Verilen tur adina sabit bir renk atar. Esleme [GenreCatalog.all]
  /// icindeki (alfabetik, sabit) siraya dayanir; boylece verideki tur sayisi
  /// veya sirasi degisse bile ayni tur her zaman ayni rengi alir.
  static Color forGenre(String genre) {
    if (genre == 'Diğer') return other;
    final index = GenreCatalog.all.indexOf(genre);
    final safeIndex = index >= 0 ? index : genre.hashCode.abs();

    final hueSlot = safeIndex % _hueSlots;
    final band = (safeIndex ~/ _hueSlots) % _lightness.length;
    final hue =
        (hueSlot * _hueStep + band * (_hueStep / _lightness.length)) % 360;

    return HSLColor.fromAHSL(1, hue, _saturation[band], _lightness[band])
        .toColor();
  }
}
