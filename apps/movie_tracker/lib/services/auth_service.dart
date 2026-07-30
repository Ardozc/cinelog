import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth uzerinde ince bir katman: hesap olusturma, giris, cikis,
/// email dogrulama (OTP) ve sifre sifirlama (OTP) akislarini saglar.
class AuthService {
  AuthService._();

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static User? get currentUser => _auth.currentUser;

  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

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
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Çok fazla deneme yaptın. Biraz sonra tekrar dene.';
    }
    if (msg.contains('database error')) {
      return 'Bu kullanıcı adı alınmış olabilir. Farklı bir kullanıcı adı dene.';
    }
    return e.message;
  }
}
