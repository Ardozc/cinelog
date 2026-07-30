import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

/// Kayit sonrasi emaile gelen dogrulama kodunu (Supabase OTP) girme ekrani.
/// Kod uzunlugu Supabase proje ayarina gore degisebildigi icin sabit
/// haneli bir kisit uygulanmiyor.
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  bool _verified = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Kodu gir.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await AuthService.verifySignupOtp(widget.email, code);
      // verifyOTP basariyla dogrulayip otomatik oturum aciyor; kullaniciyi
      // dogrudan icin sokmak yerine cikis yapip login ekranina yonlendiriyoruz.
      await AuthService.signOut();
      if (!mounted) return;
      setState(() => _verified = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });
    try {
      await AuthService.resendSignupOtp(widget.email);
      setState(() => _info = 'Kod tekrar gönderildi.');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Doğrulama'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: _verified ? _buildSuccess(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('Hesabın doğrulandı!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Giriş ekranına yönlendiriliyorsun...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined,
            size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text('${widget.email} adresine gönderilen kodu gir',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 12,
          style: Theme.of(context).textTheme.headlineMedium,
          decoration: const InputDecoration(
            hintText: 'Kod',
            counterText: '',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        if (_info != null) ...[
          const SizedBox(height: 4),
          Text(_info!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _verify,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Doğrula'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _resending ? null : _resend,
          child: Text(_resending ? 'Gönderiliyor...' : 'Kodu tekrar gönder'),
        ),
      ],
    );
  }
}
