import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/status_chip.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/features/attendance/presentation/providers/summary_providers.dart';
import 'package:mobile/core/models/attendance_summary_models.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(
      monthlySummaryProvider(
        MonthYearParams(year: _currentMonth.year, month: _currentMonth.month),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
      ),
      body: Column(
        children: [
          // Month Picker
          _MonthHeader(
            month: _currentMonth,
            onMonthChanged: (month) => setState(() => _currentMonth = month),
          ),

          // Content
          Expanded(
            child: summaryAsync.when(
              data: (summary) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(monthlySummaryProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Calendar Grid
                      _CalendarGrid(
                        month: _currentMonth,
                        calendar: summary.calendar,
                        onDateSelected: (date, status) {
                          _showAttendanceDetail(context, date, status);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Month Summary Card
                      _MonthSummaryCard(summary: summary),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              loading: () => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SkeletonLoader(height: 320, borderRadius: BorderRadius.circular(20)),
                    const SizedBox(height: 16),
                    SkeletonLoader(height: 200, borderRadius: BorderRadius.circular(20)),
                  ],
                ),
              ),
              error: (error, stack) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(monthlySummaryProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetail(BuildContext context, DateTime date, DayStatus? status) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AttendanceDetailSheet(date: date, status: status),
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  final AttendanceSummaryModel summary;

  const _MonthSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Bulan Ini',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(context, 'Hadir', '${summary.totalPresent} hari', AppColors.success),
            _buildSummaryRow(context, 'Telat', '${summary.totalLate} hari (${summary.totalMinutesLate} mnt)', AppColors.warningYellow),
            _buildSummaryRow(context, 'Cuti', '${summary.totalLeave} hari', AppColors.info),
            _buildSummaryRow(context, 'Sakit', '${summary.totalSick} hari', AppColors.purple),
            _buildSummaryRow(context, 'Izin', '${summary.totalPermission} hari', AppColors.cyan),
            _buildSummaryRow(context, 'Dinas', '${summary.totalDinas} hari', AppColors.teal),
            _buildSummaryRow(context, 'Alfa', '${summary.totalAbsent} hari', AppColors.alpha),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget implements PreferredSizeWidget {
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;

  const _MonthHeader({required this.month, required this.onMonthChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onMonthChanged(DateTime(month.year, month.month - 1)),
          ),
          Text(
            DateFormat('MMMM yyyy', 'id_ID').format(month),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onMonthChanged(DateTime(month.year, month.month + 1)),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<String, DayStatus> calendar;
  final Function(DateTime, DayStatus?) onDateSelected;

  const _CalendarGrid({
    required this.month,
    required this.calendar,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDay = DateTime(month.year, month.month, 1);
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    final totalCells = startWeekday + daysInMonth;
    final totalRows = ((totalCells + 6) / 7).ceil();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Weekday header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                .map((d) => SizedBox(
                      width: 40,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar cells
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: totalRows * 7,
            itemBuilder: (context, index) {
              final dayNumber = index - startWeekday + 1;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              
              if (!isCurrentMonth) {
                return const SizedBox.shrink();
              }

              final dateStr = '${month.year}-${month.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
              final status = calendar[dateStr];
              final statusColor = _getStatusColor(status?.status);
              final isToday = dayNumber == DateTime.now().day && month.month == DateTime.now().month && month.year == DateTime.now().year;

              return GestureDetector(
                onTap: () => onDateSelected(DateTime(month.year, month.month, dayNumber), status),
                child: Container(
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isToday
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday
                              ? Border.all(color: theme.colorScheme.primary, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              color: isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      if (statusColor != null)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color? _getStatusColor(String? status) {
    switch (status) {
      case 'present':
      case 'late_tolerance':
        return AppColors.success;
      case 'late_yellow':
        return AppColors.warningYellow;
      case 'late_red':
        return AppColors.error;
      case 'leave':
        return AppColors.info;
      case 'sick':
        return AppColors.purple;
      case 'permission':
        return AppColors.cyan;
      case 'dinas':
        return AppColors.teal;
      case 'holiday':
        return AppColors.grey;
      case 'absent':
        return AppColors.alpha;
      default:
        return null;
    }
  }
}

class _AttendanceDetailSheet extends StatelessWidget {
  final DateTime date;
  final DayStatus? status;

  const _AttendanceDetailSheet({required this.date, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusType = status?.status ?? 'future';

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      maxChildSize: 0.7,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy', 'id_ID').format(date),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    StatusChip(
                      label: _getStatusLabel(statusType),
                      type: _getStatusType(statusType),
                      outline: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow(context, 'Jam Masuk', status?.checkIn ?? '-'),
                _buildDetailRow(context, 'Jam Pulang', status?.checkOut ?? '-'),
                _buildDetailRow(
                  context,
                  'Keterlambatan',
                  status?.lateMinutes != null && status!.lateMinutes! > 0
                      ? '${status!.lateMinutes} menit'
                      : 'Tepat waktu',
                ),
                if (status?.isDinas == true)
                  _buildDetailRow(context, 'Keterangan', 'Dinas Luar Kota', AppColors.teal),
                if (status?.isOffline == true)
                  _buildDetailRow(context, 'Mode', 'Tercatat Offline', AppColors.warningYellow),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, [Color? color]) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'present': return 'Hadir';
      case 'late_tolerance': return 'Toleransi Telat';
      case 'late_yellow': return 'Telat (Kuning)';
      case 'late_red': return 'Telat (Merah)';
      case 'leave': return 'Cuti';
      case 'sick': return 'Sakit';
      case 'permission': return 'Izin';
      case 'dinas': return 'Dinas';
      case 'holiday': return 'Libur';
      case 'absent': return 'Alfa';
      default: return 'Belum ada data';
    }
  }

  StatusType _getStatusType(String status) {
    switch (status) {
      case 'present':
      case 'late_tolerance': return StatusType.present;
      case 'late_yellow': return StatusType.lateYellow;
      case 'late_red': return StatusType.lateRed;
      case 'leave': return StatusType.leave;
      case 'sick': return StatusType.sick;
      case 'permission': return StatusType.permission;
      case 'dinas': return StatusType.dinas;
      case 'holiday': return StatusType.holiday;
      case 'absent': return StatusType.absent;
      default: return StatusType.offline;
    }
  }
}
