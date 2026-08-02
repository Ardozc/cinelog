import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../main_shell.dart';
import 'login_screen.dart';

/// Oturum durumuna gore ana ekrani (MainShell) veya giris ekranini gosterir.
/// Ayrica oturum acilinca/kapaninca StorageService'in Supabase onbellegini
/// yukler/temizler (signedIn/initialSession -> yukle, signedOut -> temizle;
/// tokenRefreshed gibi diger olaylarda gereksiz yeniden yukleme yapilmaz).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _sub;

  @override
  void initState() {
    super.initState();
    _sub = AuthService.authStateChanges.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
          StorageService.loadForCurrentUser();
          break;
        case AuthChangeEvent.signedOut:
          StorageService.clear();
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        if (session != null) return const MainShell();
        return const LoginScreen();
      },
    );
  }
}
