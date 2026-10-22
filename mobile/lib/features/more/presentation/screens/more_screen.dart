import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/core/widgets/confirm_dialog.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/notification/presentation/providers/notification_providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Lainnya'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Akun'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
            title: Text(
              authState.user?.name ?? 'Pengguna',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              authState.user?.email ?? '',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => context.push('/profile'),
            ),
          ),
          const Divider(height: 1),

          const _SectionHeader(title: 'Pengaturan'),
          _buildThemeSelector(context, ref),
          ListTile(
            leading: Icon(Icons.language, color: theme.colorScheme.primary),
            title: const Text('Bahasa'),
            trailing: Text('Bahasa Indonesia'),
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
            title: const Text('Notifikasi'),
            trailing: Switch(
              value: true,
              activeThumbColor: AppColors.primary,
              onChanged: (value) {},
            ),
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            title: const Text('Versi Aplikasi'),
            trailing: Text('v1.0.0'),
          ),
          const Divider(height: 1),

          const _SectionHeader(title: 'Notifikasi'),
          ListTile(
            leading: Icon(Icons.notifications, color: theme.colorScheme.primary),
            title: const Text('Manajemen Notifikasi'),
            subtitle: unreadCount > 0
                ? Text('$unreadCount belum dibaca')
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton.icon(
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context: context,
                  title: 'Keluar',
                  content: 'Anda yakin ingin keluar dari aplikasi?',
                  confirmText: 'Keluar',
                  isDestructive: true,
                );
                if (confirmed == true && context.mounted) {
                  ref.read(authStateProvider.notifier).logout();
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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

    return ExpansionTile(
      leading: Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
      title: const Text('Tema Aplikasi'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: ThemeMode.values.map((mode) {
        final selected = current == mode;
        return ListTile(
          contentPadding: const EdgeInsets.only(left: 32),
            leading: Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
            size: 18,
          ),
          title: Text(getLabel(mode)),
          onTap: () {
            ref.read(themeModeProvider.notifier).state = mode;
            ThemeSettings.saveThemeMode(mode);
            Navigator.pop(context);
          },
        );
      }).toList(growable: false),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
