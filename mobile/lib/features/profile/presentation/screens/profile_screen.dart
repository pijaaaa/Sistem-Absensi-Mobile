import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                _getInitials(user?.name ?? ''),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.name ?? 'Pengguna',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),

            // Profile Details
            _buildDetailCard(context, [
              _buildDetailItem(context, Icons.person_outline, 'Nama', user?.name ?? '-'),
              _buildDetailItem(context, Icons.work_outline, 'Role', _getRoleLabel(user?.role)),
              _buildDetailItem(context, Icons.badge_outlined, 'Email', user?.email ?? '-'),
              if (user?.employee != null)
                _buildDetailItem(context, Icons.numbers, 'NIP', user!.employee!.nip),
            ]),
            const SizedBox(height: 16),

            // Device Status
            _buildDetailCard(context, [
              _buildDetailItem(context, Icons.phone_android, 'Device Utama', 'Pixel 8a'),
              _buildDetailItem(context, Icons.phone, 'Device Cadangan', 'None'),
            ]),
            const SizedBox(height: 24),

            // Settings
            _buildSettingItem(context, Icons.palette_outlined, 'Tema Aplikasi', _buildThemeSelector(context, ref)),
            _buildSettingItem(context, Icons.language, 'Bahasa', Text('Bahasa Indonesia')),
            _buildSettingItem(context, Icons.notifications_outlined, 'Notifikasi', Text('Aktif')),
            _buildSettingItem(context, Icons.info_outline, 'Versi Aplikasi', Text('1.0.0')),
            const SizedBox(height: 24),

            // Logout Button
            FilledButton.icon(
              onPressed: () {
                ref.read(authStateProvider.notifier).logout();
                context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text('v1.0.0', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 1).toUpperCase();
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'karyawan':
        return 'Karyawan';
      case 'manager_department':
        return 'Manager Department';
      case 'superadmin':
        return 'Super Admin';
      default:
        return role ?? '-';
    }
  }

  Widget _buildDetailCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String label, Widget trailing) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      trailing: trailing,
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    String getLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.system:
          return 'Sistem';
        case ThemeMode.light:
          return 'Terang';
        case ThemeMode.dark:
          return 'Gelap';
      }
    }

    return MenuAnchor(
      builder: (context, controller, child) {
        return FilledButton.icon(
          onPressed: () => controller.open(),
          icon: const Icon(Icons.palette, size: 16),
          label: Text(getLabel(current), style: const TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        );
      },
      menuChildren: [
        for (final mode in ThemeMode.values)
          MenuItemButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).state = mode;
              ThemeSettings.saveThemeMode(mode);
            },
            child: Text(getLabel(mode)),
          ),
      ],
    );
  }
}
