import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/notification/presentation/providers/notification_providers.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  Map<String, bool>? _prefs;
  bool _saving = false;

  static const _labels = {
    'reminder_checkin': 'Pengingat absen masuk',
    'reminder_checkout': 'Pengingat absen pulang',
    'reminder_forgot_checkout': 'Pengingat lupa absen pulang',
    'leave_balance_expiring': 'Sisa cuti akan hangus',
    'team_daily_summary': 'Ringkasan harian tim',
  };

  static const _managerOnly = {'team_daily_summary'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final authState = ref.watch(authStateProvider);
    final isManager = authState.user?.role == 'manager_department';

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Notifikasi')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Gagal memuat: $e',
              style: TextStyle(color: theme.colorScheme.error)),
        ),
        data: (serverPrefs) {
          _prefs ??= Map.from(serverPrefs);
          final visibleTypes = _labels.keys
              .where((t) => !_managerOnly.contains(t) || isManager)
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Pengingat',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...visibleTypes.map((type) => SwitchListTile(
                    title: Text(_labels[type]!),
                    value: _prefs![type] ?? true,
                    onChanged: _saving
                        ? null
                        : (val) {
                            setState(() => _prefs![type] = val);
                            _save();
                          },
                  )),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Tidak dapat dimatikan',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _fixedTile('Approval & keputusan cuti/izin'),
              _fixedTile('Kehadiran device cadangan'),
              _fixedTile('Tercatat alfa'),
              _fixedTile('Sinkronisasi offline'),
              _fixedTile('Device baru terdaftar'),
            ],
          );
        },
      ),
    );
  }

  Widget _fixedTile(String label) {
    return SwitchListTile(
      title: Text(label),
      value: true,
      onChanged: null,
    );
  }

  Future<void> _save() async {
    if (_prefs == null) return;
    setState(() => _saving = true);
    try {
      final ds = ref.read(notificationDataSourceProvider);
      await ds.updatePreferences(_prefs!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
