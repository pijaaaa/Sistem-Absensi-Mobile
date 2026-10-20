import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/confirm_dialog.dart';
import 'package:mobile/core/widgets/status_chip.dart';

class ApprovalScreen extends ConsumerWidget {
  const ApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approval'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Pengajuan'),
              Tab(text: 'Kehadiran'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LeaveApprovals(),
            _AttendanceApprovals(),
          ],
        ),
      ),
    );
  }
}

class _LeaveApprovals extends StatelessWidget {
  const _LeaveApprovals();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      {
        'name': 'Fikri Ramadhan',
        'type': 'cuti',
        'label': 'Cuti Tahunan',
        'date': '15-20 Okt 2026',
        'reason': 'Libur keluarga',
      },
      {
        'name': 'Andi Wijaya',
        'type': 'izin',
        'label': 'Izin Sakit',
        'date': '12 Okt 2026',
        'reason': 'Demam',
      },
    ];

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Tidak ada pengajuan yang perlu disetujui',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final type = item['type'] as String;
        final icon = type == 'cuti' ? Icons.calendar_today : Icons.medical_information_outlined;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(item['label'] as String? ?? '',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  StatusChip(label: 'Pending', type: StatusType.pending, outline: true),
                ],
              ),
              const SizedBox(height: 12),
              Text('Periode: ${item['date']}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('Alasan: ${item['reason']}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(text: 'Setuju', onPressed: () => _handleApprove(context), backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(text: 'Tolak', onPressed: () => _handleReject(context), outline: true, backgroundColor: AppColors.error),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleApprove(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Setujui?',
      content: 'Anda yakin ingin menyetujui pengajuan ini?',
      confirmText: 'Setujui',
      isDestructive: false,
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan disetujui')),
      );
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Tolak?',
      content: 'Tolak pengajuan ini?',
      confirmText: 'Tolak',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan ditolak')),
      );
    }
  }
}

class _AttendanceApprovals extends StatelessWidget {
  const _AttendanceApprovals();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      {
        'name': 'Siti Rahayu',
        'date': '19 Okt 2026',
        'time': '08:30',
        'status': 'Late',
        'device': 'Device Cadangan',
      },
    ];

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Tidak ada kehadiran yang perlu disetujui',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] as String? ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${item['date']} • ${item['time']}',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  StatusChip(label: item['status'] as String? ?? '', type: StatusType.lateYellow, outline: true),
                ],
              ),
              const SizedBox(height: 12),
              Text('Device: ${item['device']}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(text: 'Setuju', onPressed: () => _handleApprove(context), backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(text: 'Tolak', onPressed: () => _handleReject(context), outline: true, backgroundColor: AppColors.error),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleApprove(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Setujui?',
      content: 'Anda yakin ingin menyetujui kehadiran ini?',
      confirmText: 'Setujui',
      isDestructive: false,
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disetujui')),
      );
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Tolak?',
      content: 'Tolak kehadiran ini?',
      confirmText: 'Tolak',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ditolak')),
      );
    }
  }
}
