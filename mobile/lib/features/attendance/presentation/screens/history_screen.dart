import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/status_chip.dart';

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

          // Calendar Grid
          _CalendarGrid(
            month: _currentMonth,
            onDateSelected: (date) {
              _showAttendanceDetail(context, date);
            },
          ),

          const SizedBox(height: 8),

          // Month Summary
          _buildMonthSummary(context),
        ],
      ),
    );
  }

  void _showAttendanceDetail(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AttendanceDetailSheet(date: date),
    );
  }

  Widget _buildMonthSummary(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan ${_formatMonth(_currentMonth)}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(context, 'Hadir', '22 hari', AppColors.success),
            _buildSummaryRow(context, 'Telat', '3 hari', AppColors.warningYellow),
            _buildSummaryRow(context, 'Cuti', '2 hari', AppColors.info),
            _buildSummaryRow(context, 'Izin', '1 hari', AppColors.cyan),
            _buildSummaryRow(context, 'Alfa', '0 hari', AppColors.alpha),
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
              const SizedBox(width: 6),
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
      padding: const EdgeInsets.all(16),
      color: theme.cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onMonthChanged(DateTime(month.year, month.month - 1)),
          ),
          Text(
            _formatMonth(month),
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

  static String _formatMonth(DateTime date) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Dummy calendar implementation
class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarGrid({required this.month, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDay = DateTime(month.year, month.month, 1);
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    final totalCells = startWeekday + daysInMonth;
    final totalRows = ((totalCells + 6) / 7).ceil();

    return Expanded(
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
          // Calendar cells
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemCount: totalRows * 7,
              itemBuilder: (context, index) {
                final dayNumber = index - startWeekday + 1;
                final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
                final isToday = isCurrentMonth && dayNumber == DateTime.now().day && month.month == DateTime.now().month && month.year == DateTime.now().year;

                // Assign dummy status colors for demo
                final statusColor = _getRandomStatusColor(dayNumber);

                return GestureDetector(
                  onTap: isCurrentMonth
                      ? () => onDateSelected(DateTime(month.year, month.month, dayNumber))
                      : null,
                  child: Container(
                    alignment: Alignment.topCenter,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isCurrentMonth)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$dayNumber',
                                style: TextStyle(
                                  color: isToday ? Colors.white : theme.colorScheme.onSurface,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        if (isCurrentMonth && statusColor != null)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              width: 8,
                              height: 8,
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
          ),
        ],
      ),
    );
  }

  Color? _getRandomStatusColor(int day) {
    // Dummy status assignment based on day for demo
    if (day % 5 == 0) return AppColors.alpha;
    if (day % 4 == 0) return AppColors.warningYellow;
    if (day % 7 == 0) return AppColors.grey;
    return AppColors.success;
  }
}

class _AttendanceDetailSheet extends StatelessWidget {
  final DateTime date;

  const _AttendanceDetailSheet({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
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
                Text(
                  '${date.day} ${AppColors.success.toString()} ${_getMonthName(date.month)} ${date.year}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildDetailRow(context, 'Masuk', isToday ? '08:05' : null, isToday ? AppColors.success : null),
                _buildDetailRow(context, 'Pulang', isToday ? '17:05' : null, isToday ? AppColors.success : null),
                _buildDetailRow(context, 'Keterlambatan', isToday ? '0 min' : null, AppColors.success),
                _buildDetailRow(context, 'Pulang awal', '-', AppColors.error),
                const SizedBox(height: 16),
                StatusChip(
                  label: 'Tepat waktu',
                  type: StatusType.present,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value, Color? color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(
            value ?? '-',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

String _getMonthName(int month) {
  const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
  return months[month];
}

String _formatMonth(DateTime date) {
  return '${_getMonthName(date.month)} ${date.year}';
}
