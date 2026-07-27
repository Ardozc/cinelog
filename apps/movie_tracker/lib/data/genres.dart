/// TMDb'nin resmi tur (genre) kataloglari (tr-TR). Film ve dizi turleri
/// kismen farkli id/isim setlerine sahiptir (ör. "Aksiyon & Macera" sadece
/// dizilerde, "Aksiyon" ve "Macera" ayri ayri sadece filmlerde bulunur).
class GenreCatalog {
  GenreCatalog._();

  static const Map<int, String> movie = {
    28: 'Aksiyon',
    12: 'Macera',
    16: 'Animasyon',
    35: 'Komedi',
    80: 'Suç',
    99: 'Belgesel',
    18: 'Dram',
    10751: 'Aile',
    14: 'Fantastik',
    36: 'Tarih',
    27: 'Korku',
    10402: 'Müzik',
    9648: 'Gizem',
    10749: 'Romantik',
    878: 'Bilim-Kurgu',
    10770: 'TV film',
    53: 'Gerilim',
    10752: 'Savaş',
    37: 'Vahşi Batı',
  };

  static const Map<int, String> tv = {
    10759: 'Aksiyon & Macera',
    16: 'Animasyon',
    35: 'Komedi',
    80: 'Suç',
    99: 'Belgesel',
    18: 'Dram',
    10751: 'Aile',
    10762: 'Çocuklar',
    9648: 'Gizem',
    10763: 'Haber',
    10764: 'Gerçeklik',
    10765: 'Bilim Kurgu & Fantazi',
    10766: 'Pembe Dizi',
    10767: 'Talk',
    10768: 'Savaş & Politik',
    37: 'Vahşi Batı',
  };

  /// Filtre chip'lerinde gosterilen, film + dizi turlerinin birlesimi (alfabetik).
  static final List<String> all = {...movie.values, ...tv.values}.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  static Map<int, String> _catalogFor(String mediaType) =>
      mediaType == 'tv' ? tv : movie;

  static List<String> namesForIds(List<int> ids, String mediaType) {
    final catalog = _catalogFor(mediaType);
    return ids.map((id) => catalog[id]).whereType<String>().toList();
  }

  static List<int> idsForNames(Set<String> names, String mediaType) {
    final catalog = _catalogFor(mediaType);
    return catalog.entries
        .where((e) => names.contains(e.value))
        .map((e) => e.key)
        .toList();
  }
}
