import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'verify_email_screen.dart';

/// Kayit ekrani: email + sifre + sifre tekrar.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Kullanıcı adı, email ve şifre gerekli.');
      return;
    }
    if (!_usernamePattern.hasMatch(username)) {
      setState(() => _error =
          'Kullanıcı adı 3-20 karakter olmalı, sadece harf/rakam/_ içerebilir.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Şifre en az 8 karakter olmalı.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Şifreler eşleşmiyor.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final available = await AuthService.isUsernameAvailable(username);
      if (!available) {
        setState(() => _error = 'Bu kullanıcı adı zaten alınmış.');
        return;
      }
      await AuthService.signUp(email, password, username);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Hesap oluştur',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text('Film ve dizi arşivini oluşturmaya başla',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 28),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Kullanıcı adı',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
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
              const SizedBox(height: 14),
              TextField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  hintText: 'Şifre (tekrar)',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kayıt Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
