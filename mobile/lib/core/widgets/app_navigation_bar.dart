import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/menu_item_model.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class AppNavigationBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int>? onDestinationSelected;

  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    this.onDestinationSelected,
  });

  static const _iconMap = <String, IconData>{
    'home': Icons.home,
    'history': Icons.history,
    'leave': Icons.calendar_today,
    'profile': Icons.person,
    'approval': Icons.check_circle,
    'more': Icons.menu,
  };

  static const _branchRoutes = <String>[
    '/home',
    '/history',
    '/leave',
    '/approval',
    '/profile',
    '/more',
  ];

  static const _routeMap = <String, String>{
    'home': '/home',
    'history': '/history',
    'leave': '/leave',
    'approval': '/approval',
    'profile': '/profile',
    'more': '/more',
  };

  static const _hiddenKeys = <String>{
    'notifications',
    'attendance',
    'team_stats',
  };

  static final _homeItem = MenuItemModel(
    featureKey: 'home',
    label: 'Beranda',
    icon: 'home',
  );

  static final _moreItem = MenuItemModel(
    featureKey: 'more',
    label: 'Lainnya',
    icon: 'menu',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = _visibleDestinations(
      ref.watch(currentMenusProvider),
      currentIndex,
    );

    return NavigationBar(
      selectedIndex: _destinationIndexForBranch(destinations, currentIndex),
      onDestinationSelected: (index) {
        final branchIndex = _branchIndexForDestination(destinations, index);
        if (branchIndex == null || branchIndex == currentIndex) return;
        onDestinationSelected?.call(branchIndex);
      },
      indicatorColor: _getIndicatorColor(context),
      destinations: destinations.map((item) {
        final icon =
            _iconMap[item.featureKey] ?? _iconMap[item.icon] ?? Icons.widgets;
        return NavigationDestination(
          icon: Icon(icon, size: 22),
          label: item.label,
          tooltip: item.label,
        );
      }).toList(),
    );
  }

  List<MenuItemModel> _visibleDestinations(
    List<Map<String, dynamic>>? raw,
    int branchIndex,
  ) {
    final seen = <String>{};
    final eligible = <MenuItemModel>[];

    for (final entry in raw ?? const <Map<String, dynamic>>[]) {
      final item = MenuItemModel.fromJson(entry);
      final key = item.featureKey;
      if (key.isEmpty ||
          _hiddenKeys.contains(key) ||
          !_routeMap.containsKey(key) ||
          !seen.add(key)) {
        continue;
      }
      eligible.add(item);
    }

    final visible = eligible.take(5).toList();
    if ((eligible.length > 5 ||
            branchIndex == _branchRoutes.indexOf('/more')) &&
        !visible.any((item) => item.featureKey == 'more')) {
      visible.add(_moreItem);
    }
    if (branchIndex == 0 && !visible.any((item) => item.featureKey == 'home')) {
      visible.insert(0, _homeItem);
    }

    if (visible.length < 2) {
      if (!visible.any((item) => item.featureKey == 'home')) {
        visible.insert(0, _homeItem);
      }
      if (!visible.any((item) => item.featureKey == 'more')) {
        visible.add(_moreItem);
      }
    }

    return visible;
  }

  int _destinationIndexForBranch(
    List<MenuItemModel> destinations,
    int branchIndex,
  ) {
    final route = branchIndex >= 0 && branchIndex < _branchRoutes.length
        ? _branchRoutes[branchIndex]
        : '/home';
    final index = destinations.indexWhere(
      (item) => _routeMap[item.featureKey] == route,
    );
    return index == -1 ? 0 : index;
  }

  int? _branchIndexForDestination(
    List<MenuItemModel> destinations,
    int destinationIndex,
  ) {
    if (destinationIndex < 0 || destinationIndex >= destinations.length) {
      return null;
    }
    final route = _routeMap[destinations[destinationIndex].featureKey];
    if (route == null) return null;
    final branchIndex = _branchRoutes.indexOf(route);
    return branchIndex == -1 ? null : branchIndex;
  }

  Color _getIndicatorColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppColors.darkSurfaceHigh.withValues(alpha: 0.5)
        : AppColors.primary.withValues(alpha: 0.12);
  }
}
