import '../models/user_entry.dart';

/// Ana sayfa ve favoriler ekranindaki siralama secenekleri.
/// Ilk secenek ("Varsayilan"), "Listeye Eklenme (Yeni → Eski)" ile ayni
/// sekilde calisir.
const List<String> sortOptions = [
  'Varsayılan',
  'Listeye Eklenme (Yeni → Eski)',
  'Listeye Eklenme (Eski → Yeni)',
  'Ada (A → Z)',
  'Ada (Z → A)',
  'Çıkış Yılı (Yeni → Eski)',
  'Çıkış Yılı (Eski → Yeni)',
  'TMDb Puanı (Yüksek → Düşük)',
  'TMDb Puanı (Düşük → Yüksek)',
  'Benim Puanım (Yüksek → Düşük)',
  'Benim Puanım (Düşük → Yüksek)',
];

int _releaseYear(UserEntry e) => e.releaseDate.length >= 4
    ? int.tryParse(e.releaseDate.substring(0, 4)) ?? 0
    : 0;

/// Secili secenegin birincil karsilastirmasi. Esitlik durumunda (ör. ayni
/// puana sahip iki kayit) 0 doner ve nihai sira [sortEntries] icindeki
/// eklenme-tarihi tie-break'i ile belirlenir.
int _primaryCompare(UserEntry a, UserEntry b, String option) {
  switch (option) {
    case 'Listeye Eklenme (Yeni → Eski)':
      return b.addedAt.compareTo(a.addedAt);
    case 'Listeye Eklenme (Eski → Yeni)':
      return a.addedAt.compareTo(b.addedAt);
    case 'Ada (A → Z)':
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    case 'Ada (Z → A)':
      return b.title.toLowerCase().compareTo(a.title.toLowerCase());
    case 'Çıkış Yılı (Yeni → Eski)':
      return _releaseYear(b).compareTo(_releaseYear(a));
    case 'Çıkış Yılı (Eski → Yeni)':
      return _releaseYear(a).compareTo(_releaseYear(b));
    case 'TMDb Puanı (Yüksek → Düşük)':
      return b.tmdbRating.compareTo(a.tmdbRating);
    case 'TMDb Puanı (Düşük → Yüksek)':
      return a.tmdbRating.compareTo(b.tmdbRating);
    case 'Benim Puanım (Yüksek → Düşük)':
      return b.userRating.compareTo(a.userRating);
    case 'Benim Puanım (Düşük → Yüksek)':
      return a.userRating.compareTo(b.userRating);
    default:
      return 0; // Varsayilan: sira tamamen tie-break'e birakilir
  }
}

/// Verilen listeyi secili siralama secenegine gore sirlar.
/// Zaten filtrelenmis (medya/tur/arama) bir liste uzerinde calisir; bu sayede
/// siralama mevcut filtrelerle uyumlu kalir.
///
/// Birincil karsilastirma esit sonuc verirse (veya "Varsayilan" seciliyse)
/// eklenme tarihine (yeni -> eski) gore sabit bir tie-break uygulanir.
/// Bu, `List.sort`'un stabil olmamasindan dogabilecek belirsiz siralamayi
/// (ör. bir kaydin duzenlenmesinin baska kayitlarin yerini degistirmesini)
/// engeller.
List<UserEntry> sortEntries(List<UserEntry> entries, String option) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final primary = _primaryCompare(a, b, option);
    if (primary != 0) return primary;
    return b.addedAt.compareTo(a.addedAt);
  });
  return sorted;
}
