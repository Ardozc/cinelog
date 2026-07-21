import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';

/// Uygulamanin ana iskeleti: 4 sekmeli alt navigasyon + ortadaki FAB.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch({bool focusField = false}) {
    setState(() => _index = 1);
    if (focusField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
  }

  void _openProfile() => setState(() => _index = 3);

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final screens = [
      HomeScreen(
        onSearchTap: () => _openSearch(focusField: true),
        onProfileTap: _openProfile,
        onNotificationsTap: _openNotifications,
      ),
      SearchScreen(focusNode: _searchFocusNode),
      const StatisticsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      floatingActionButton: _index == 1
          ? null
          : FloatingActionButton(
              onPressed: () => _openSearch(focusField: true),
              backgroundColor: primary,
              elevation: 2,
              shape: const CircleBorder(),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: _BottomNav(
          index: _index,
          onChanged: (i) => i == 1 ? _openSearch() : setState(() => _index = i),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _BottomNav({required this.index, required this.onChanged});

  static const _items = [
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Ana Sayfa'),
    (
      icon: Icons.search_outlined,
      active: Icons.search_rounded,
      label: 'Keşfet'
    ),
    (
      icon: Icons.bar_chart_outlined,
      active: Icons.bar_chart_rounded,
      label: 'İstatistik'
    ),
    (
      icon: Icons.person_outline_rounded,
      active: Icons.person_rounded,
      label: 'Profil'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final bg = isDark ? AppColors.darkCard : Colors.white;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_items.length, (i) {
          final selected = i == index;
          final item = _items[i];
          return GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                selected ? item.active : item.icon,
                color: selected
                    ? primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
                size: 24,
              ),
            ),
          );
        }),
      ),
    );
  }
}
