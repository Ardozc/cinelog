# movie_tracker (Cinelog)

Film ve dizi takip için Flutter uygulaması. TMDb kataloğundan içerik aranır, kullanıcının kişisel listesine (puan, not, izleme durumu, tarihler, favori) eklenir; bu veri Supabase üzerinde hesap bazlı olarak saklanır ve cihazlar arasında gerçek zamanlı senkronize edilir.

Genel proje bilgisi ve monorepo yapısı için köklerdeki [`README.md`](../../README.md) dosyasına bakın. Bu dosya doğrudan bu Flutter uygulamasının teknik referansıdır.

## İçindekiler

- [Kullanılan Teknolojiler](#kullanılan-teknolojiler)
- [Paketler](#paketler)
- [Authentication Sistemi](#authentication-sistemi)
- [Supabase Kullanımı](#supabase-kullanımı)
- [Database Yapısı](#database-yapısı)
- [RLS ve Authorization Yaklaşımı](#rls-ve-authorization-yaklaşımı)
- [TMDb API Kullanımı](#tmdb-api-kullanımı)
- [Film/Dizi Özellikleri](#filmdizi-özellikleri)
- [Favorites, Watchlist ve Watch Status](#favorites-watchlist-ve-watch-status)
- [Filtreleme ve Sıralama](#filtreleme-ve-sıralama)
- [Kullanıcı Profili ve İstatistikler](#kullanıcı-profili-ve-istatistikler)
- [Proje Klasör Yapısı](#proje-klasör-yapısı)
- [Kurulum](#kurulum)
- [Environment / Configuration](#environment--configuration)
- [Komutlar](#komutlar)
- [Güvenlik Kuralları](#güvenlik-kuralları)
- [Geliştirme Notları](#geliştirme-notları)

## Kullanılan Teknolojiler

- **Flutter** (test edilen sürüm: 3.44.8 stable) / **Dart** (`pubspec.yaml` SDK constraint: `>=3.0.0 <4.0.0`), Material 3
- **Google Fonts:** başlıklar Poppins, gövde metni Inter
- Harici bir state-management paketi (Provider/Riverpod/Bloc vb.) kullanılmıyor — ekranlar `StatefulWidget` + `StorageService.changes` adlı bir `ValueNotifier<int>` ile yeniden çiziliyor
- Desteklenen platformlar: Android, iOS, Web, Windows, macOS, Linux (hepsi repoda mevcut)

## Paketler

`pubspec.yaml`'daki başlıca bağımlılıklar:

| Paket | Amaç |
|---|---|
| `supabase_flutter` | Auth, Postgres (REST), Realtime istemcisi |
| `flutter_dotenv` | `.env` dosyasından ortam değişkeni yükleme |
| `flutter_secure_storage` | Supabase oturum belirtecinin güvenli (Keystore/Keychain) depolanması |
| `http` | TMDb API çağrıları |
| `cached_network_image` | Poster/afiş görsellerinin önbellekli yüklenmesi |
| `fl_chart` | İstatistik ekranındaki grafikler |
| `google_fonts` | Poppins/Inter font aileleri |
| `intl` | Tarih biçimlendirme |
| `cupertino_icons` | İkon seti |

Geliştirme bağımlılıkları: `flutter_test`, `flutter_lints`.

## Authentication Sistemi

Kimlik doğrulama tamamen Supabase Auth (GoTrue) üzerine, `lib/services/auth_service.dart` içindeki ince bir katmanla kurulu:

- **Kayıt:** email + şifre + kullanıcı adı. Kayıt sırasında kullanıcı adının müsaitliği `is_username_available` RPC'siyle anında kontrol edilir (bkz. [RLS ve Authorization](#rls-ve-authorization-yaklaşımı)).
- **Email doğrulama:** magic link yerine sayısal bir kod (OTP) kullanılır; kodun uzunluğu istemci tarafında sabitlenmemiştir, Supabase proje ayarına göre değişebilir (şu an 6 hane). Doğrulama durumu Supabase'in kendi sunucu taraflı `email_confirmed_at` alanından okunur — istemci tarafında ayrıca tutulan/yazılabilen bir bayrağa dayanmaz.
- **Giriş:** email veya kullanıcı adıyla yapılabilir. Kullanıcı adı girildiğinde, karşılık gelen email adresi yalnızca doğru şifre birlikte verildiğinde sunucu tarafında çözülür (bkz. [RLS ve Authorization Yaklaşımı](#rls-ve-authorization-yaklaşımı)) — bu adres istemciye başka türlü ifşa edilmez.
- **Şifremi unuttum:** email'e gönderilen sayısal kodla doğrulama, ardından yeni şifre belirleme.
- **Oturum yönetimi:** `AuthGate` (`lib/screens/auth/auth_gate.dart`) uygulama açılışında ve `AppLifecycleState.resumed` olduğunda (uygulama ön plana döndüğünde) oturumun sunucu tarafında hâlâ geçerli olup olmadığını doğrular — hesap Supabase tarafında silinmişse kullanıcı otomatik olarak login ekranına yönlendirilir.
- **Hesap silme:** Profil ekranından self-servis olarak, `delete_own_account` RPC'si üzerinden.

## Supabase Kullanımı

Uygulama `supabase_flutter` istemcisini üç ana amaçla kullanır:

1. **Auth** (`GoTrueClient`) — yukarıdaki bölüm; ayrıca `lib/services/auth_service.dart` içinde `.rpc(...)` ile kullanıcı adı/email çözümleme ve hesap silme fonksiyonları çağrılır.
2. **Postgres REST** (`SupabaseClient.from(...)`) — `lib/services/storage_service.dart`, kullanıcının izleme listesini (`entries` tablosu) okur/yazar.
3. **Realtime** — `entries` tablosunda kullanıcının kendi `user_id`'sine filtrelenmiş bir `postgres_changes` aboneliği açılır; başka bir cihazdan gelen ekleme/güncelleme/silme olduğunda liste otomatik olarak yeniden çekilir ve ekranlar `changes` üzerinden anlık güncellenir. (Bunun çalışması için Supabase projesinde `entries` tablosunda Realtime'ın açık olması gerekir.)

Uygulama açılışında `Supabase.initialize(...)` çağrısı `lib/main.dart` içinde yapılır; oturum kalıcılığı için varsayılan (düz metin) depolama yerine özel bir `SecureLocalStorage` (`lib/services/secure_local_storage.dart`) implementasyonu kullanılır.

## Database Yapısı

Şu an iki tablo var:

**`entries`** — kullanıcının kişisel listesindeki her kayıt bir satır:

| Kolon | Açıklama |
|---|---|
| `user_id` | Sahip kullanıcının UUID'si (`auth.uid()`) |
| `movie_id`, `media_type` | TMDb kimliği ve tür (`movie` / `tv`) |
| `title`, `poster_path`, `genre`, `genres`, `release_date`, `tmdb_rating` | TMDb'den gelen bilgiler |
| `user_rating`, `note`, `status` | Kullanıcının kendi puanı, notu, izleme durumu |
| `started_at`, `completed_at`, `dropped_at` | Duruma göre ilgili tarih |
| `favorite` | Favori işareti |
| `added_at` | Listeye eklenme tarihi |

`(user_id, movie_id, media_type)` üçlüsü tekil kabul edilir (aynı içerik aynı kullanıcı için tek satırda tutulur, `upsert` ile güncellenir).

**`profiles`** — `id` (auth kullanıcı UUID'si), `username`, `created_at`. Kullanıcı kaydolduğunda `handle_new_user` trigger fonksiyonu bu satırı otomatik oluşturur.

## RLS ve Authorization Yaklaşımı

Her iki tabloda da Row Level Security **açık**:

- **`entries`:** Dört ayrı policy (SELECT/INSERT/UPDATE/DELETE), hepsi `authenticated` rolüne kısıtlı ve `auth.uid() = user_id` şartını taşır — SELECT/DELETE `USING`, INSERT `WITH CHECK`, UPDATE hem `USING` hem `WITH CHECK` ile korunur. İstemciden gelen `user_id` değerine güvenilmez: okuma/silme işleminde satır önce `USING` ile "bu satır gerçekten bana mı ait" diye süzülür, ekleme/güncellemede ise gönderilen `user_id`'nin `auth.uid()`'e eşit olması `WITH CHECK` ile zorunlu kılınır. Sonuç olarak bir kullanıcı başka bir kullanıcının satırını okuyamaz, oluşturamaz, güncelleyemez veya silemez.
- **`profiles`:** Hiçbir doğrudan client erişimi yok (0 RLS policy'si, `anon`/`authenticated` rollerine tablo düzeyinde de grant verilmemiş). Tabloya erişim yalnızca aşağıdaki `SECURITY DEFINER` fonksiyonlar üzerinden, dar ve amaca özel şekilde sağlanır:

| Fonksiyon | Kim çağırabilir | Ne yapar |
|---|---|---|
| `is_username_available(uname)` | `anon`, `authenticated` | Sadece `true`/`false` döner, satır ifşa etmez |
| `get_email_for_username(uname, pass)` | `anon`, `authenticated` | Yalnızca doğru şifre verilirse email döner; yanlış şifrede veya kullanıcı yoksa `null` — kullanıcı adından email adresi toplu olarak çıkarılamasın diye kasıtlı olarak şifre doğrulamalı tasarlanmıştır |
| `delete_own_account()` | `authenticated` | Yalnızca çağıranın kendi `auth.uid()`'ine ait `entries`, `profiles` ve `auth.users` kayıtlarını siler; parametre almaz |
| `handle_new_user()`, `set_updated_at()` | yalnızca trigger olarak (doğrudan RPC çağrısı için grant yok) | Kayıt sonrası profil oluşturma / `updated_at` bakımı |

RLS/RPC tanımları Supabase Dashboard'un SQL Editor'ünde elle uygulanır; bu değişikliklerin kaydı `supabase/manual_migrations/` altında tutulur. Bu klasör tabloların ilk oluşturulma (`CREATE TABLE`) SQL'ini **içermez** — yalnızca sonradan uygulanan RLS/RPC düzeltme ve sertleştirme script'lerinin kaydıdır; gerçek bir `supabase db` migration zinciri değildir.

## TMDb API Kullanımı

`lib/services/tmdb_service.dart`, TMDb v3 REST API'sini sarmalar:

- `search/multi` — birleşik film/dizi/kişi araması (yalnızca film/dizi sonuçları filtrelenir)
- `trending/{media}/week` ve `discover/{movie|tv}` (tür filtresi + `sort_by=popularity.desc`) — Keşfet sekmesindeki sayfalı listeler
- `movie/{id}` / `tv/{id}` — detay sayfası

Tüm istekler `language=tr-TR` varsayılan parametresiyle yapılır. TMDb anahtarı `.env` üzerinden yüklenir.

## Film/Dizi Özellikleri

- TMDb'de birleşik arama (Keşfet sekmesi) ve kategori/tür bazlı keşfet (trend + discover, sayfalama destekli)
- Detay ekranında TMDb bilgisi (poster, puan, özet vb.) ile kullanıcının kendi girişi (puan, not, durum, tarihler, favori) birlikte gösterilir ve tek ekrandan düzenlenir
- Ana sayfa arama kutusu, TMDb'de değil kullanıcının **kendi kayıtlı listesinde** anlık başlık araması yapar

## Favorites, Watchlist ve Watch Status

`WatchStatus` enum'u (`lib/models/watch_status.dart`) beş durumu tanımlar: **İzlenecek, İzleniyor, Tamamlandı, Tekrar İzlenecek, Bırakıldı** — her biri kendi rengiyle. Favori (`favorite`) ayrı, bağımsız bir boolean alandır (bir izleme durumu değildir); Favoriler sekmesi yalnızca `favorite = true` olan kayıtları listeler.

## Filtreleme ve Sıralama

Ana sayfa ve Favoriler ekranlarında aynı iki bileşen kullanılır:

- **Sırala (`SortButton`):** Varsayılan, Listeye Eklenme (Yeni→Eski / Eski→Yeni), Ada Göre (A→Z / Z→A), Çıkış Yılı, TMDb Puanı, Benim Puanım (her biri artan/azalan) — tek seçim.
- **Filtrele (`FilterButton`):** Kategori (Hepsi/Film/Dizi, tek seçim), Tür (TMDb tür kataloğundan çoklu seçim), İzleme Durumu (çoklu seçim) — üçü birlikte, sıralamayla uyumlu şekilde çalışır.

## Kullanıcı Profili ve İstatistikler

**Profil ekranı:** gerçek kullanıcı adı (Supabase hesap metadata'sından), toplam film/dizi/favori sayısı, ortalama puan, duruma göre sayaçlar, en sevilen tür; çıkış yap ve hesabı sil.

**İstatistik ekranı:** tür dağılımı (en çok izlenenden aza, "Tüm Türleri Gör" ile tam liste), son 6 ayın tamamlanan yapım sayısı ve son 7 günün aktivite grafiği (`fl_chart` ile), toplam tahmini izleme süresi.

*(Not: "Bildirimler" ekranı arayüzde mevcut ama şu an yalnızca boş-durum placeholder'ıdır; bir bildirim altyapısına bağlı değildir.)*

## Proje Klasör Yapısı

```
lib/
├── data/            Statik veri: TMDb tür kataloğu, sıralama seçenekleri, tür istatistik yardımcıları
├── models/          Movie, UserEntry, WatchStatus
├── screens/
│   ├── auth/        AuthGate, LoginScreen, SignupScreen, VerifyEmailScreen, ForgotPasswordScreen
│   ├── home_screen.dart, favorites_screen.dart, search_screen.dart
│   ├── detail_screen.dart, genre_detail_screen.dart
│   ├── statistics_screen.dart, profile_screen.dart, notifications_screen.dart
│   └── main_shell.dart          5 sekmeli alt navigasyon iskeleti
├── services/        AuthService, StorageService, TmdbService, SecureLocalStorage
├── theme/           Renk paleti, light/dark ThemeData
├── widgets/         MovieCard, SearchResultCard, SortButton, FilterButton, RatingSelector,
│                    StatusSelector, CategoryChip, GenreFilterChips, GlassContainer
└── main.dart
```

## Kurulum

1. Flutter SDK kurulu olmalı (bu projede test edilen sürüm: Flutter 3.44.8 stable).
2. Bir Supabase projesi oluşturun; [Database Yapısı](#database-yapısı) bölümündeki kolonlarla `entries` ve `profiles` tablolarını, [RLS ve Authorization](#rls-ve-authorization-yaklaşımı) bölümünde açıklanan policy'leri ve RPC fonksiyonlarını kurun (RLS/RPC düzeltmelerinin SQL kaydı için `supabase/manual_migrations/` — tablo oluşturma script'lerini içermez).
3. [themoviedb.org](https://www.themoviedb.org/settings/api) üzerinden ücretsiz bir TMDb API anahtarı alın.
4. `.env` dosyasını oluşturun (bkz. aşağıdaki bölüm).
5. Bağımlılıkları kurun ve çalıştırın:

```bash
flutter pub get
flutter run
```

## Environment / Configuration

Proje kökünde (`apps/movie_tracker/.env`) — bu dosya `.gitignore`'dadır, repoya eklenmemelidir:

```env
SUPABASE_URL=https://<proje-ref>.supabase.co
SUPABASE_ANON_KEY=<supabase-publishable-anahtari>
TMDB_API_KEY=<tmdb-api-anahtari>
```

`.env`, `pubspec.yaml`'da bir Flutter asset'i olarak tanımlıdır ve `flutter_dotenv` ile `main()` başında yüklenir. `SUPABASE_ANON_KEY` client-safe (publishable) bir anahtardır; gerçek güvenlik sınırı RLS'tir, anahtarın gizliliği değil. `SUPABASE_URL`/`SUPABASE_ANON_KEY` her ortamda aynı kalabilir, `TMDB_API_KEY`'i kendi hesabınızdan almanız gerekir.

## Komutlar

```bash
flutter pub get     # bağımlılıkları indir/güncelle
flutter analyze     # statik analiz (flutter_lints kurallarıyla)
flutter test        # test paketini çalıştır
flutter run         # geliştirme modunda çalıştır (-d <device> ile platform seçilebilir)
```

## Güvenlik Kuralları

Bu projede katkıda bulunurken uyulması gereken ilkeler:

- Yeni eklenen her tabloda RLS **açık** olmalı; en az SELECT/INSERT/UPDATE/DELETE için ayrı, `authenticated` rolüne kısıtlı, `auth.uid() = <sahiplik kolonu>` şartlı policy tanımlanmalı.
- `user_id`/`owner_id` gibi sahiplik alanlarına istemciden gelen değer asla doğrudan güvenilmemeli — INSERT/UPDATE'te mutlaka `WITH CHECK (auth.uid() = ...)` ile sunucu tarafında doğrulanmalı.
- `service_role` anahtarı veya başka bir yönetici/gizli anahtar **hiçbir zaman** istemci koduna veya `.env`'e eklenmemeli; istemci yalnızca `anon`/publishable anahtarı kullanır.
- Yeni bir `SECURITY DEFINER` fonksiyon eklerken `EXECUTE` izni yalnızca gerçekten ihtiyacı olan role (`anon`/`authenticated`) verilmeli; varsayılan geniş `PUBLIC` grant'i kaldırılmalı.
- `.env` asla commit edilmemeli; `SUPABASE_URL`/`SUPABASE_ANON_KEY` dışında hiçbir gizli değer istemci tarafında saklanmamalı.
- Oturum verisi `flutter_secure_storage` üzerinden platformun güvenli deposunda tutulur; bu davranış değiştirilmemeli (düz metin depolamaya geri dönülmemeli).

## Geliştirme Notları

- Basit tutulan state-management yaklaşımı bilinçli bir tercihtir; yeni bir paket eklemeden önce mevcut `ValueNotifier` deseninin yeterli olup olmadığı değerlendirilmeli.
- `test/` dizininde şu an yalnızca temel bir smoke test var; kapsamlı bir test paketi henüz yok.
- RLS policy'leri ve RPC fonksiyonları bir Supabase CLI migration zinciriyle değil, Dashboard SQL Editor üzerinden elle yönetiliyor; şema değişikliklerinin `supabase/manual_migrations/` altında SQL olarak kaydını tutmak (gerçek migration'ın yerine geçmese de) izlenebilirlik için önemlidir.
- `flutter analyze`'ın temiz geçmesi (uyarısız) commit öncesi beklenen asgari kontroldür.
