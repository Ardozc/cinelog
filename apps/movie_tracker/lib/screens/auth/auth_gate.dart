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
///
/// Dogrulanmamis (AuthService.isVerified == false) bir oturum hicbir zaman
/// MainShell'e gecirilmiyor: AuthService.signIn zaten boyle bir oturumu
/// hemen kapatiyor, ama o kapanana kadarki kisa surede bile MainShell'e
/// gecip geri donmemek onemli - aksi halde LoginScreen widget'i bu geciste
/// yok edilip yeniden olusturulur ve gosterilecek hata mesaji kaybolur.
///
/// Cihazda saklanan oturum, hesap Supabase'den (Dashboard'dan) silinmis
/// olsa bile JWT suresi dolana kadar "gecerli" gorunmeye devam eder. Bunu
/// yakalamak icin acilista ve uygulama on plana her donduginde sunucuya
/// sorup (AuthService.verifySessionStillValid) hesabin hala var oldugunu
/// dogruluyoruz; degilse oturumu kapatip giris ekranina donuyoruz.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  late final StreamSubscription<AuthState> _sub;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = AuthService.authStateChanges.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
          if (AuthService.isVerified(state.session?.user)) {
            StorageService.loadForCurrentUser();
          } else {
            StorageService.clear();
          }
          break;
        case AuthChangeEvent.signedOut:
          StorageService.clear();
          break;
        default:
          break;
      }
    });
    _verifyThenReady();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _verifySession();
  }

  Future<void> _verifyThenReady() async {
    await _verifySession();
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _verifySession() async {
    if (Supabase.instance.client.auth.currentSession == null) return;
    final stillValid = await AuthService.verifySessionStillValid();
    if (!stillValid) await AuthService.signOut();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        if (session != null && AuthService.isVerified(session.user)) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
