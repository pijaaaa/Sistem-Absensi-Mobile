import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/confirm_dialog.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/features/approval/presentation/providers/approval_providers.dart';
import 'package:intl/intl.dart';

class ApprovalScreen extends ConsumerStatefulWidget {
  const ApprovalScreen({super.key});

  @override
  ConsumerState<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends ConsumerState<ApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Pengajuan'),
            Tab(text: 'Kehadiran'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LeaveApprovals(selectedStatus: _selectedStatus),
          _AttendanceApprovals(selectedStatus: _selectedStatus),
        ],
      ),
    );
  }
}

class _LeaveApprovals extends ConsumerWidget {
  final String selectedStatus;

  const _LeaveApprovals({required this.selectedStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final approvalAsync = ref.watch(
      approvalInboxProvider(
        ApprovalInboxParams(type: 'leave', status: selectedStatus),
      ),
    );

    return approvalAsync.when(
      data: (items) {
        final pendingItems = items.where((item) => item.isPending).toList();

        if (pendingItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    size: 48, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('Tidak ada pengajuan yang perlu disetujui',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(approvalInboxProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pendingItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = pendingItems[index];
              return _LeaveApprovalCard(item: item);
            },
          ),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(height: 180, borderRadius: BorderRadius.circular(20)),
        ),
      ),
      error: (error, stack) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(approvalInboxProvider),
      ),
    );
  }
}

class _LeaveApprovalCard extends ConsumerWidget {
  final dynamic item;

  const _LeaveApprovalCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final type = item.leaveType ?? 'cuti';
    final icon = _getLeaveIcon(type);
    final label = _getLeaveLabel(type);
    final dateRange = _formatDateRange(item.startDate, item.endDate);

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
                    Text(item.employeeName ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(label,
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              StatusChip(
                  label: 'Pending', type: StatusType.pending, outline: true),
            ],
          ),
          const SizedBox(height: 12),
          Text('Periode: $dateRange', style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('Alasan: ${item.reason ?? '-'}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Setuju',
                  onPressed: () => _handleApprove(context, ref, item.id),
                  backgroundColor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Tolak',
                  onPressed: () => _handleReject(context, ref, item.id),
                  outline: true,
                  backgroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getLeaveIcon(String type) {
    switch (type) {
      case 'cuti':
        return Icons.calendar_today;
      case 'sakit':
        return Icons.medical_services;
      case 'izin':
        return Icons.assignment_outlined;
      case 'dinas':
        return Icons.business_center;
      default:
        return Icons.calendar_today;
    }
  }

  String _getLeaveLabel(String type) {
    switch (type) {
      case 'cuti':
        return 'Cuti Tahunan';
      case 'sakit':
        return 'Sakit';
      case 'izin':
        return 'Izin';
      case 'dinas':
        return 'Dinas';
      default:
        return type;
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '-';
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    if (end == null || start == end) {
      return formatter.format(start);
    }
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  Future<void> _handleApprove(
      BuildContext context, WidgetRef ref, int requestId) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Setujui?',
      content: 'Anda yakin ingin menyetujui pengajuan ini?',
      confirmText: 'Setujui',
      isDestructive: false,
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(approvalActionProvider.notifier)
          .approveLeaveRequest(requestId);

      final state = ref.read(approvalActionProvider);
      if (context.mounted) {
        state.when(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengajuan disetujui')),
            );
          },
          loading: () {},
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          },
        );
      }
    }
  }

  Future<void> _handleReject(
      BuildContext context, WidgetRef ref, int requestId) async {
    final reasonController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tolak Pengajuan',
                style:
                    Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan',
                hintText: 'Masukkan alasan penolakan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Batal',
                    onPressed: () => Navigator.of(context).pop(false),
                    outline: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Tolak',
                    onPressed: () {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Alasan harus diisi')),
                        );
                        return;
                      }
                      Navigator.of(context).pop(true);
                    },
                    backgroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final reason = reasonController.text.trim();
      await ref
          .read(approvalActionProvider.notifier)
          .rejectLeaveRequest(requestId, reason);

      final state = ref.read(approvalActionProvider);
      if (context.mounted) {
        state.when(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengajuan ditolak')),
            );
          },
          loading: () {},
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          },
        );
      }
    }

    reasonController.dispose();
  }
}

class _AttendanceApprovals extends ConsumerWidget {
  final String selectedStatus;

  const _AttendanceApprovals({required this.selectedStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final approvalAsync = ref.watch(
      approvalInboxProvider(
        ApprovalInboxParams(type: 'attendance', status: selectedStatus),
      ),
    );

    return approvalAsync.when(
      data: (items) {
        final pendingItems = items.where((item) => item.isPending).toList();

        if (pendingItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    size: 48, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('Tidak ada kehadiran yang perlu disetujui',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(approvalInboxProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pendingItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = pendingItems[index];
              return _AttendanceApprovalCard(item: item);
            },
          ),
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(height: 150, borderRadius: BorderRadius.circular(20)),
        ),
      ),
      error: (error, stack) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(approvalInboxProvider),
      ),
    );
  }
}

class _AttendanceApprovalCard extends ConsumerWidget {
  final dynamic item;

  const _AttendanceApprovalCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateTime = item.attendanceDate != null
        ? DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(item.attendanceDate!)
        : '-';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.employeeName ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(dateTime,
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              StatusChip(
                label: item.checkType == 'in' ? 'Masuk' : 'Pulang',
                type: StatusType.onTime,
                outline: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_android,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Device Cadangan',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Setuju',
                  onPressed: () => _handleApprove(context, ref, item.id),
                  backgroundColor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Tolak',
                  onPressed: () => _handleReject(context, ref, item.id),
                  outline: true,
                  backgroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(
      BuildContext context, WidgetRef ref, int attendanceId) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Setujui Kehadiran?',
      content:
          'Anda yakin ingin menyetujui kehadiran dari device cadangan ini?',
      confirmText: 'Setuju',
      isDestructive: false,
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(approvalActionProvider.notifier)
          .approveAttendance(attendanceId);

      final state = ref.read(approvalActionProvider);
      if (context.mounted) {
        state.when(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kehadiran disetujui')),
            );
          },
          loading: () {},
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          },
        );
      }
    }
  }

  Future<void> _handleReject(
      BuildContext context, WidgetRef ref, int attendanceId) async {
    final reasonController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tolak Kehadiran',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan',
                hintText: 'Masukkan alasan penolakan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Batal',
                    onPressed: () => Navigator.of(context).pop(false),
                    outline: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Tolak',
                    onPressed: () {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alasan harus diisi')),
                        );
                        return;
                      }
                      Navigator.of(context).pop(true);
                    },
                    backgroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final reason = reasonController.text.trim();
      await ref
          .read(approvalActionProvider.notifier)
          .rejectAttendance(attendanceId, reason);

      final state = ref.read(approvalActionProvider);
      if (context.mounted) {
        state.when(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kehadiran ditolak')),
            );
          },
          loading: () {},
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          },
        );
      }
    }

    reasonController.dispose();
  }
}
