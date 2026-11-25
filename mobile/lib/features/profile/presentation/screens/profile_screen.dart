import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/app_state_provider.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/core/widgets/section_header.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/auth/presentation/providers/device_providers.dart';
import 'package:mobile/features/auth/presentation/widgets/logout_confirmation_dialog.dart';
import 'package:mobile/features/face/presentation/providers/face_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildHeaderBanner(context, user?.name ?? 'Pengguna',
              user?.email ?? '', _getRoleLabel(user?.role)),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Informasi Akun'),
          const SizedBox(height: 10),
          _buildDetailCard(context, [
            _buildDetailItem(context, Icons.person_outline, 'Nama', user?.name ?? '-'),
            _buildDetailItem(context, Icons.work_outline, 'Role', _getRoleLabel(user?.role)),
            _buildDetailItem(context, Icons.badge_outlined, 'Email', user?.email ?? '-'),
            if (user?.employee != null)
              _buildDetailItem(context, Icons.numbers, 'NIP', user!.employee!.nip),
          ]),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Status Perangkat'),
          const SizedBox(height: 10),
          _buildDeviceStatusCard(context, ref),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Pengaturan'),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingItem(
                  context,
                  Icons.palette_outlined,
                  'Tema Aplikasi',
                  _buildThemeSelector(context, ref),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  context,
                  Icons.language,
                  'Bahasa',
                  Text('Bahasa Indonesia', style: theme.textTheme.bodySmall),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
                  title: const Text('Notifikasi'),
                  subtitle: const Text('Atur pengingat yang ingin diterima'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/notification-preferences'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.face_retouching_natural, color: theme.colorScheme.primary),
                  title: const Text('Daftar Wajah'),
                  subtitle: const Text('Registrasi wajah untuk absensi'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/enrollment'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.face_unlock_outlined, color: theme.colorScheme.error),
                  title: Text('Hapus Data Wajah', style: TextStyle(color: theme.colorScheme.error)),
                  subtitle: const Text('Reset atau hapus template wajah terdaftar'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Data Wajah'),
                        content: const Text('Apakah Anda yakin ingin menghapus data wajah terdaftar? Anda perlu melakukan registrasi ulang.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );
                        final dataSource = ref.read(faceDataSourceProvider);
                        await dataSource.deleteFace();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data wajah berhasil dihapus')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal menghapus data wajah: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  context,
                  Icons.info_outline,
                  'Versi Aplikasi',
                  Text('1.0.0', style: theme.textTheme.bodySmall),
                ),
              ],
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
          const SizedBox(height: 16),
          Center(
            child: Text(
              'v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(
    BuildContext context,
    String name,
    String email,
    String role,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _getInitials(name),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    role,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, 1).toUpperCase();
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

  Widget _buildDeviceStatusCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deviceStatusAsync = ref.watch(deviceStatusProvider);
    final currentDeviceAsync = ref.watch(currentDeviceInfoProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Status Device',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            deviceStatusAsync.when(
              data: (deviceStatus) {
                if (deviceStatus == null) {
                  return Column(
                    children: [
                      Text(
                        'Device belum terdaftar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      currentDeviceAsync.when(
                        data: (deviceInfo) => Text(
                          deviceInfo['device_name'] ?? 'Unknown Device',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _buildDeviceRow(
                      context,
                      icon: deviceStatus.isPrimary ? Icons.phone_android : Icons.phone_iphone,
                      label: deviceStatus.isPrimary ? 'Device Utama' : 'Device Cadangan',
                      value: deviceStatus.name,
                      color: deviceStatus.isPrimary ? AppColors.primary : AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                    _buildDeviceRow(
                      context,
                      icon: Icons.check_circle,
                      label: 'Status',
                      value: deviceStatus.isActive ? 'Aktif' : 'Nonaktif',
                      color: deviceStatus.isActive ? AppColors.onTime : AppColors.error,
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Gagal memuat status device',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
