import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Bildirimler icin hazir ekran. Bildirim altyapisi eklendiginde liste burada
/// doldurulacak; simdilik bos durum gosterir.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_none_rounded,
                      color: primary, size: 38),
                ),
                const SizedBox(height: 18),
                Text(
                  'Henüz bildirim yok',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Yeni hatırlatmalar ve güncellemeler burada görünecek.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
