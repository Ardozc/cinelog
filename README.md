# Cinelog

Film ve dizi takip uygulaması. Kullanıcılar TMDb kataloğundan film/dizi arar, kişisel listelerine ekler; puan, not ve izleme durumu (izlenecek / izleniyor / tamamlandı / tekrar izlenecek / bırakıldı) takip eder, favori işaretler ve izleme istatistiklerini görüntüler.

## Temel Özellikler

- Email veya kullanıcı adıyla kayıt/giriş, sayısal kod (OTP) ile email doğrulama ve şifre sıfırlama
- TMDb üzerinden film/dizi arama ve keşfet (trend/popüler, kategori + tür filtreli)
- Kişisel liste: puan (0-10), not, izleme durumu, başlama/bitirme/bırakma tarihi, favori işareti
- Ana sayfa ve favoriler ekranında birleşik sıralama + çoklu filtre (kategori, tür, izleme durumu)
- İstatistik ekranı: toplam film/dizi, ortalama/en yüksek puan, tür dağılımı, aylık/haftalık aktivite grafikleri
- Hesap verilerinin cihazlar arası gerçek zamanlı senkronizasyonu
- Self-servis hesap silme

## Teknolojiler

- **İstemci:** Flutter / Dart (Android, iOS, Web, Windows, macOS, Linux)
- **Backend:** [Supabase](https://supabase.com) — Auth, Postgres (Row Level Security), Realtime
- **Dış veri kaynağı:** [TMDb](https://www.themoviedb.org/documentation/api) (The Movie Database) API v3
- Ayrı bir state-management paketi kullanılmıyor; basit `ValueNotifier` tabanlı bir önbellek yeterli görülmüş

## Proje Yapısı

```
Cinelog/
├── apps/
│   └── movie_tracker/   Flutter uygulaması — bkz. apps/movie_tracker/README.md
└── README.md             Bu dosya
```

Bu bir monorepo'dur; şu an tek bir uygulama (`movie_tracker`) içerir. Backend ayrı bir klasör olarak repoda yer almaz — yönetilen (managed) bir Supabase projesi olarak dışarıda çalışır.

### `movie_tracker` nedir?

Uygulamanın kendisi olan Flutter projesidir. Mimari, veritabanı şeması, güvenlik yaklaşımı, kullanılan paketler ve geliştirme komutları gibi teknik detaylar için [`apps/movie_tracker/README.md`](apps/movie_tracker/README.md) dosyasına bakın.

## Kurulum (özet)

```bash
cd apps/movie_tracker
flutter pub get
flutter run
```

Uygulamanın çalışması için kendi Supabase projeniz ve bir TMDb API anahtarı gerekir; adım adım kurulum için `apps/movie_tracker/README.md`.

## Ortam Değişkenleri

`apps/movie_tracker/.env` dosyasında (git'e dahil edilmez) şu değerler tanımlanmalı:

| Değişken | Açıklama |
|---|---|
| `SUPABASE_URL` | Supabase proje URL'i |
| `SUPABASE_ANON_KEY` | Supabase publishable (anon) anahtarı — client-safe |
| `TMDB_API_KEY` | TMDb API anahtarı |

## Kullanılan Servisler

- **Supabase:** Kimlik doğrulama (email/şifre + OTP), kullanıcı verisinin (izleme listesi) Postgres'te saklanması, Row Level Security ile kullanıcı bazlı izolasyon ve cihazlar arası senkronizasyon için Realtime.
- **TMDb:** Film/dizi arama, keşfet ve detay bilgisi için salt-okunur veri kaynağı.

## Güvenlik

- Tüm kullanıcı verisi Postgres Row Level Security ile korunur; bir kullanıcı yalnızca kendi kayıtlarını okuyabilir/değiştirebilir.
- İstemciye hiçbir zaman Supabase `service_role` veya başka bir yönetici anahtarı gömülmez — yalnızca client-safe `anon`/publishable anahtar kullanılır.
- Oturum belirteçleri cihazın güvenli deposunda (Android Keystore / iOS Keychain) saklanır.
- Ayrıntılı güvenlik notları için `apps/movie_tracker/README.md`.

## Geliştirme

```bash
cd apps/movie_tracker
flutter analyze   # statik analiz
flutter test      # testler
```

## Lisans

Bu proje şu an özel (private) bir kişisel projedir; herhangi bir açık kaynak lisansı altında yayınlanmamıştır. Tüm hakları saklıdır.
