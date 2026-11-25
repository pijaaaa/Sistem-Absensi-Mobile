import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/app_state_provider.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/core/widgets/app_avatar.dart';
import 'package:mobile/core/widgets/section_header.dart';
import 'package:mobile/features/auth/presentation/widgets/logout_confirmation_dialog.dart';
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
      appBar: AppBar(title: const Text('Lainnya'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.go('/profile'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AppAvatar(
                      name: authState.user?.name ?? 'Pengguna',
                      size: 52,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.user?.name ?? 'Pengguna',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            authState.user?.email ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Pengaturan'),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _buildThemeSelector(context, ref),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Bahasa'),
                  trailing: Text(
                    'Bahasa Indonesia',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Notifikasi'),
                  trailing: Switch(
                    value: true,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) {},
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Versi Aplikasi'),
                  trailing: Text('v1.0.0', style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Notifikasi'),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: const Text('Manajemen Notifikasi'),
              subtitle: unreadCount > 0
                  ? Text('$unreadCount belum dibaca')
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/notifications'),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await handleLogoutWithOfflineCheck(context, ref, () {
                  ref.read(appStateProvider.notifier).logout();
                });
              },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
      children: ThemeMode.values
          .map((mode) {
            final selected = current == mode;
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 32),
              leading: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? AppColors.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
              title: Text(getLabel(mode)),
              onTap: () {
                ref.read(themeModeProvider.notifier).state = mode;
                ThemeSettings.saveThemeMode(mode);
                Navigator.pop(context);
              },
            );
          })
          .toList(growable: false),
    );
  }
}
