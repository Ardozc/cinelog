import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'verify_email_screen.dart';

/// Giris ekrani: email veya kullanici adi + sifre, sifremi unuttum ve kayit linkleri.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  bool _needsVerification = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email/kullanıcı adı ve şifre gerekli.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _needsVerification = false;
    });
    try {
      await AuthService.signIn(identifier, password);
      // Basarili olursa AuthGate stream'i yakalayip MainShell'e gecer.
    } catch (e) {
      setState(() {
        _error = e.toString();
        _needsVerification = _error!.contains('doğrulanmamış');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToVerify() async {
    final identifier = _identifierController.text.trim();
    final email = await AuthService.resolveEmail(identifier) ?? identifier;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.movie_filter_rounded, size: 56, color: primary),
                const SizedBox(height: 16),
                Text('CineLog',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 6),
                Text('Film ve dizi arşivine giriş yap',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                TextField(
                  controller: _identifierController,
                  decoration: const InputDecoration(
                    hintText: 'Email veya kullanıcı adı',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen()),
                            ),
                    child: const Text('Şifremi unuttum'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  if (_needsVerification) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _goToVerify,
                      child: const Text('Doğrulama kodunu gir'),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Giriş Yap'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hesabın yok mu?',
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const SignupScreen()),
                              ),
                      child: const Text('Kayıt ol'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
