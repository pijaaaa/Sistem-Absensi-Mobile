import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:intl/intl.dart';

// History tab
class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(
      leaveRequestsProvider(
        LeaveRequestsParams(status: _selectedStatus),
      ),
    );

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua', null),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Disetujui', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('Ditolak', 'rejected'),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada pengajuan',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(leaveRequestsProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _LeaveRequestCard(request: request);
                  },
                ),
              );
            },
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonLoader(
                  height: 140,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            error: (error, stack) => ErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(leaveRequestsProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedStatus = status;
        });
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _LeaveRequestCard extends ConsumerWidget {
  final dynamic request;

  const _LeaveRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _getTypeColor().withValues(alpha: 0.1),
                child: Icon(_getTypeIcon(), color: _getTypeColor(), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.typeLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${dateFormatter.format(request.startDate)} - ${dateFormatter.format(request.endDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: _getStatusLabel(),
                type: _getStatusType(),
                outline: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.reason,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (request.isRejected && request.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alasan: ${request.rejectionReason}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (request.isPending) ...[
            const SizedBox(height: 12),
            AppButton(
              text: 'Batalkan',
              onPressed: () => _cancelRequest(context, ref),
              outline: true,
              backgroundColor: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (request.type) {
      case 'cuti':
        return AppColors.info;
      case 'sakit':
        return AppColors.purple;
      case 'izin':
        return AppColors.cyan;
      case 'dinas':
        return AppColors.teal;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (request.type) {
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

  String _getStatusLabel() {
    if (request.isPending) return 'Pending';
    if (request.isApproved) return 'Disetujui';
    if (request.isRejected) return 'Ditolak';
    return request.status;
  }

  StatusType _getStatusType() {
    if (request.isPending) return StatusType.pending;
    if (request.isApproved) return StatusType.approved;
    if (request.isRejected) return StatusType.rejected;
    return StatusType.pending;
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pengajuan'),
        content: const Text('Anda yakin ingin membatalkan pengajuan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(leaveSubmissionProvider.notifier).cancelRequest(request.id);

      final state = ref.read(leaveSubmissionProvider);
      if (context.mounted) {
        state.when(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengajuan dibatalkan')),
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
}
