import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth uzerinde ince bir katman: hesap olusturma, giris, cikis,
/// email dogrulama (OTP) ve sifre sifirlama (OTP) akislarini saglar.
class AuthService {
  AuthService._();

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static User? get currentUser => _auth.currentUser;

  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// [cinelog_signup_verified] bayragi hic yoksa (bu fix'ten once acilmis
  /// hesap) kisitlama uygulamiyoruz; varsa true olmasi gerekiyor.
  static bool isVerified(User? user) {
    final metadata = user?.userMetadata;
    if (metadata == null || !metadata.containsKey('cinelog_signup_verified')) {
      return true;
    }
    return metadata['cinelog_signup_verified'] == true;
  }

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
        // NOT: metadata anahtari kasitli olarak 'email_verified' DEGIL.
        // GoTrue, user_metadata icindeki 'email_verified'/'phone_verified'
        // alanlarini rezerve tutuyor ve email herhangi bir OTP turuyle
        // (signup DAHIL recovery ile de) dogrulaninca bu alani kendisi
        // otomatik true yapiyor - denenip dogrulandi. O yuzden kendi
        // bayragimizi farkli bir isimle tutuyoruz ki sadece bizim
        // verifySignupOtp cagrimiz onu true yapabilsin, recovery akisi
        // dokunamasin.
        data: {'username': username, 'cinelog_signup_verified': false},
      );
    } on AuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// [identifier] email veya kullanici adi olabilir. Kullanici adiysa once
  /// `get_email_for_username` RPC'siyle karsilik gelen email'e cevrilir.
  static Future<void> signIn(String identifier, String password) async {
    final email = await resolveEmail(identifier);
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
  /// karsilik gelen email'i sorgular. Bulunamazsa null doner.
  static Future<String?> resolveEmail(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) return trimmed;
    try {
      final result = await Supabase.instance.client
          .rpc('get_email_for_username', params: {'uname': trimmed});
      return result as String?;
    } catch (_) {
      return null;
    }
  }

  /// Kayit formunda aninda "bu kullanici adi alinmis mi" kontrolu icin.
  static Future<bool> isUsernameAvailable(String username) async {
    final result = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return result == null;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> verifySignupOtp(String email, String token) async {
    try {
      await _auth.verifyOTP(
        type: OtpType.signup,
        email: email,
        token: token,
      );
      try {
        await _auth.updateUser(
            UserAttributes(data: {'cinelog_signup_verified': true}));
      } catch (_) {
        // Metadata guncellemesi basarisiz olsa da OTP dogrulamasi tamamlandi;
        // kullaniciyi hataya dusurmemek icin sessizce yut. Kullanici bir
        // sonraki girişte tekrar engellenirse "Kodu tekrar gönder" ile
        // yeniden dogrulayabilir.
      }
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
