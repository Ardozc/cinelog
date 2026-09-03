import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth uzerinde ince bir katman: hesap olusturma, giris, cikis,
/// email dogrulama (OTP) ve sifre sifirlama (OTP) akislarini saglar.
class AuthService {
  AuthService._();

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static User? get currentUser => _auth.currentUser;

  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Dogrulama durumu GoTrue'nun kendi sunucu-taraf `email_confirmed_at`
  /// alanindan okunur (client'in yazabildigi `user_metadata` gibi degil -
  /// bu alani sadece Supabase, gercek bir OTP dogrulamasi sonrasi set eder).
  /// Onceki surumde bu bayrak `user_metadata` icinde tutuluyordu; herhangi
  /// bir client `updateUser` cagirarak bunu kendi kendine true yapabildigi
  /// icin (GoTrue user_metadata her zaman client-writable'dir) dogrulama
  /// zorunlulugu tamamen atlatilabiliyordu. Bkz. guvenlik denetimi notlari.
  static bool isVerified(User? user) => user?.emailConfirmedAt != null;

  /// Cihazda saklanan oturum (JWT suresi dolmamis olsa bile) hesabin hala
  /// Supabase'de var oldugunu garanti etmez - hesap Dashboard'dan silinmis
  /// olabilir. Bunu ancak sunucuya sorarak (GET /user) anlayabiliriz.
  /// Ag hatasi (internet yok, gecici sunucu sorunu) durumunda hesabin
  /// silindigi kanitlanmadigi icin oturumu gecerli sayiyoruz (fail-open);
  /// sunucu acikca "gecersiz/bulunamadi" derse false donuyoruz.
  static Future<bool> verifySessionStillValid() async {
    if (_auth.currentSession == null) return false;
    try {
      await _auth.getUser();
      return true;
    } on AuthRetryableFetchException {
      return true;
    } on AuthException {
      return false;
    }
  }

  static Future<void> signUp(
      String email, String password, String username) async {
    try {
      await _auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
    } on AuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// [identifier] email veya kullanici adi olabilir. Kullanici adiysa once
  /// `get_email_for_username` RPC'siyle (sifre dogrulamasiyla birlikte)
  /// karsilik gelen email'e cevrilir.
  static Future<void> signIn(String identifier, String password) async {
    final email = await resolveEmail(identifier, password);
    if (email == null) {
      throw 'Kullanıcı adı veya şifre hatalı.';
    }
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw _mapError(e);
    }
    if (!isVerified(_auth.currentUser)) {
      await _auth.signOut();
      throw 'Email adresin henüz doğrulanmamış.';
    }
  }

  /// [identifier] zaten email ise oldugu gibi doner; kullanici adiysa
  /// `get_email_for_username` RPC'sine [password] ile birlikte sorulur.
  /// RPC, sifre dogru DEGILSE de kullanici bulunamadiysa da null doner -
  /// boylece bu uc nokta kimliksiz bir "email oracle"a donusmuyor (bkz.
  /// guvenlik denetimi: onceki halinde herkes sadece kullanici adi girerek
  /// gercek email adresini alabiliyordu).
  static Future<String?> resolveEmail(String identifier, String password) async {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) return trimmed;
    try {
      final result = await Supabase.instance.client.rpc(
        'get_email_for_username',
        params: {'uname': trimmed, 'pass': password},
      );
      return result as String?;
    } catch (_) {
      return null;
    }
  }

  /// Kayit formunda aninda "bu kullanici adi alinmis mi" kontrolu icin.
  /// `profiles` tablosunu dogrudan sorgulamak yerine sadece true/false
  /// donen bir RPC kullanilir (bkz. guvenlik denetimi: `profiles` tablosu
  /// artik anon/authenticated icin dogrudan SELECT edilebilir degil).
  static Future<bool> isUsernameAvailable(String username) async {
    final result = await Supabase.instance.client
        .rpc('is_username_available', params: {'uname': username});
    return result as bool;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Hesabi ve tum verilerini kalici olarak siler. Supabase'in normal
  /// istemci anahtariyla auth.users'a yazma izni olmadigi icin, veritabani
  /// tarafinda tanimlanmasi gereken (bkz. proje notlari) `delete_own_account`
  /// RPC'sini cagirir; bu fonksiyon SECURITY DEFINER ile sadece cagiran
  /// kullanicinin (auth.uid()) kendi hesabini silecek sekilde kisitlanmis
  /// olmali. Basarili olursa yerel oturumu da kapatir.
  static Future<void> deleteAccount() async {
    try {
      await Supabase.instance.client.rpc('delete_own_account');
    } on PostgrestException catch (e) {
      throw e.message;
    }
    await signOut();
  }

  static Future<void> verifySignupOtp(String email, String token) async {
    try {
      await _auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: token,
      );
      // Basarili dogrulama GoTrue'nun kendi `email_confirmed_at` alanini
      // otomatik set eder; isVerified() bunu okur, ayrica bir metadata
      // guncellemesi gerekmez (bkz. isVerified()).
    } on AuthException catch (e) {
      throw _mapError(e);
    }
  }

  static Future<void> resendSignupOtp(String email) async {
    try {
      await _auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (e) {
      throw _mapError(e);
    }
  }

  static Future<void> requestPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _mapError(e);
    }
  }

  static Future<void> verifyRecoveryOtp(String email, String token) async {
    try {
      await _auth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: token,
      );
    } on AuthException catch (e) {
      throw _mapError(e);
    }
  }

  static Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _mapError(e);
    }
  }

  static String _mapError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Email/kullanıcı adı veya şifre hatalı.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email adresin henüz doğrulanmamış.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already registered')) {
      return 'Bu email adresi zaten kayıtlı.';
    }
    if (msg.contains('token has expired') || msg.contains('otp expired')) {
      return 'Kod süresi doldu. Yeni bir kod iste.';
    }
    if (msg.contains('invalid') && msg.contains('otp')) {
      return 'Girdiğin kod hatalı.';
    }
    if (msg.contains('password') && msg.contains('at least')) {
      return 'Şifre en az 6 karakter olmalı.';
    }
    if (msg.contains('rate limit') ||
        msg.contains('too many') ||
        msg.contains('security purposes')) {
      // Supabase'in "For security purposes, you can only request this after
      // 55 seconds." mesaji "rate limit"/"too many" gecmedigi icin ayri
      // eslesme gerekiyordu; aksi halde bu mesaj ham Ingilizce olarak
      // gosteriliyordu (kullanici "kod hic gelmiyor" saniyordu).
      final match = RegExp(r'(\d+)\s*seconds?').firstMatch(msg);
      final seconds = match?.group(1);
      return seconds != null
          ? 'Yeni kod için $seconds saniye bekle.'
          : 'Çok fazla deneme yaptın. Biraz sonra tekrar dene.';
    }
    if (msg.contains('database error')) {
      return 'Bu kullanıcı adı alınmış olabilir. Farklı bir kullanıcı adı dene.';
    }
    return e.message;
  }
}
