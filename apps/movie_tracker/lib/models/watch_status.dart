import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Kullanicinin bir yapima verdigi izleme durumu.
enum WatchStatus { watchlist, watching, completed, dropped }

extension WatchStatusX on WatchStatus {
  String get label {
    switch (this) {
      case WatchStatus.watchlist:
        return 'İzlenecek';
      case WatchStatus.watching:
        return 'İzleniyor';
      case WatchStatus.completed:
        return 'Tamamlandı';
      case WatchStatus.dropped:
        return 'Bırakıldı';
    }
  }

  Color get color {
    switch (this) {
      case WatchStatus.watchlist:
        return AppColors.statusWatchlist;
      case WatchStatus.watching:
        return AppColors.statusWatching;
      case WatchStatus.completed:
        return AppColors.statusCompleted;
      case WatchStatus.dropped:
        return AppColors.statusDropped;
    }
  }

  static WatchStatus fromName(String name) => WatchStatus.values
      .firstWhere((e) => e.name == name, orElse: () => WatchStatus.watchlist);
}
