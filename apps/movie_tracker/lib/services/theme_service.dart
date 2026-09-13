import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanicinin tema tercihini (acik/koyu/telefon varsayilani) cihazda
/// kalici olarak saklar. Varsayilan (hic secim yapilmamissa) telefonun
/// kendi ayarini takip eden [ThemeMode.system]'dir.
class ThemeService {
  ThemeService._();

  static const _key = 'theme_mode';

  /// Ekranlarin dinleyip anlik guncellenebilecegi mevcut tema modu.
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.system);

  /// Uygulama acilisinda, ilk frame cizilmeden once cagrilmali.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = _fromName(prefs.getString(_key));
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  static ThemeMode _fromName(String? name) => ThemeMode.values
      .firstWhere((e) => e.name == name, orElse: () => ThemeMode.system);
}
