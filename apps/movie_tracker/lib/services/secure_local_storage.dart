import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase oturum (access/refresh token) verisini varsayilan
/// SharedPreferences/NSUserDefaults yerine platformun guvenli deposunda
/// (Android Keystore / iOS-macOS Keychain) sakla. Varsayilan depolama
/// duz metin oldugu icin cihaza fiziksel erisimi olan biri (root/jailbreak,
/// ADB backup) oturumu calabiliyordu.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'supabase.session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return (await _storage.read(key: _key)) != null;
  }

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}
