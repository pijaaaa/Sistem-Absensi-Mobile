import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/models/menu_item_model.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class AppNavigationBar extends ConsumerWidget {
  final int initialIndex;
  final ValueChanged<int>? onTap;

  const AppNavigationBar({
    super.key,
    this.initialIndex = 0,
    this.onTap,
  });

  static const _iconMap = <String, IconData>{
    'home': Icons.home,
    'attendance': Icons.fingerprint,
    'history': Icons.history,
    'leave': Icons.calendar_today,
    'profile': Icons.person,
    'approval': Icons.check_circle,
    'team_stats': Icons.bar_chart,
    'notifications': Icons.notifications,
    'more': Icons.menu,
  };

  static const _routeMap = <String, String>{
    'home': '/home',
    'attendance': '/attendance-flow',
    'history': '/history',
    'leave': '/leave',
    'profile': '/profile',
    'approval': '/approval',
    'team_stats': '/home',
    'notifications': '/notifications',
    'more': '/more',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusRaw = ref.watch(currentMenusProvider);

    if (menusRaw == null || menusRaw.isEmpty) {
      // Fallback: NavigationBar butuh minimal 2 destination — 
      // tampilkan Home + More saat menu kosong (mis. offline / menu gagal load)
      return NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          final currentLocation = GoRouterState.of(context).matchedLocation;
          final target = index == 0 ? '/home' : '/more';
          if (target != currentLocation) {
            GoRouter.of(context).go(target);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home, size: 22),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu, size: 22),
            label: 'Lainnya',
          ),
        ],
      );
    }

    final menus =
        menusRaw.map((e) => MenuItemModel.fromJson(e)).toList();
    final visibleMenus = menus
        .where((e) => e.featureKey != 'notifications' && e.featureKey != 'attendance' && e.featureKey != 'team_stats')
        .take(5)
        .toList();
    final hasMore = menus
        .where((e) => e.featureKey != 'notifications' && e.featureKey != 'attendance' && e.featureKey != 'team_stats')
        .length > 5;

    if (hasMore) {
      visibleMenus.add(MenuItemModel(
        featureKey: 'more',
        label: 'Lainnya',
        icon: 'menu',
      ));
    }

    return NavigationBar(
      selectedIndex: initialIndex.clamp(0, visibleMenus.length - 1),
      onDestinationSelected: (index) {
        final item = visibleMenus[index];
        final route = _routeMap[item.featureKey] ?? '/home';
        final currentLocation = GoRouterState.of(context).matchedLocation;
        if (route == currentLocation) return;
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        }
        GoRouter.of(context).push(route);
        onTap?.call(index);
      },
      indicatorColor: _getIndicatorColor(context),
      destinations: visibleMenus.asMap().entries.map((entry) {
        final item = entry.value;
        final icon = _iconMap[item.featureKey] ?? _iconMap[item.icon] ?? Icons.widgets;
        final label = item.label;

        return NavigationDestination(
          icon: Icon(icon, size: 22),
          label: label,
          tooltip: label,
        );
      }).toList(),
    );
  }

  Color _getIndicatorColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppColors.darkSurfaceHigh.withValues(alpha: 0.5)
        : AppColors.primary.withValues(alpha: 0.12);
  }
}
