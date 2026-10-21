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
    'fingerprint': Icons.fingerprint,
    'calendar': Icons.calendar_today,
    'document': Icons.document_scanner,
    'person': Icons.person,
    'check_circle': Icons.check_circle,
    'bar_chart': Icons.bar_chart,
    'bell': Icons.notifications,
    'history': Icons.history,
    'leave': Icons.calendar_today,
    'approval': Icons.check_circle,
    'team_stats': Icons.bar_chart,
    'notifications': Icons.notifications,
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
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusRaw = ref.watch(currentMenusProvider);

    if (menusRaw == null || menusRaw.isEmpty) {
      return const SizedBox.shrink();
    }

    final menus =
        menusRaw.map((e) => MenuItemModel.fromJson(e)).toList();
    final visibleMenus = menus.take(5).toList();
    final hasMore = menus.length > 5;

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
        if (route != GoRouterState.of(context).matchedLocation) {
          GoRouter.of(context).go(route);
        }
        onTap?.call(index);
      },
      indicatorColor: _getIndicatorColor(context),
      destinations: visibleMenus.asMap().entries.map((entry) {
        final item = entry.value;
        final icon = _iconMap[item.icon] ?? Icons.menu;
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
