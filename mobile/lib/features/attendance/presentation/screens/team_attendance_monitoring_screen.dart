import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/features/attendance/presentation/providers/team_attendance_providers.dart';
import 'package:mobile/features/attendance/presentation/widgets/employee_attendance_card.dart';

class TeamAttendanceMonitoringScreen extends ConsumerStatefulWidget {
  const TeamAttendanceMonitoringScreen({super.key});

  @override
  ConsumerState<TeamAttendanceMonitoringScreen> createState() => _TeamAttendanceMonitoringScreenState();
}

class _TeamAttendanceMonitoringScreenState extends ConsumerState<TeamAttendanceMonitoringScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchQueryProvider.notifier).state = _searchController.text;
  }

  Future<void> _selectDate(BuildContext context) async {
    final selectedDate = ref.read(selectedDateProvider);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      ref.read(selectedDateProvider.notifier).state = pickedDate;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final teamAttendanceAsync = ref.watch(teamAttendanceDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Kehadiran Tim'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date picker & search section
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                // Date picker
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatDate(selectedDate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama karyawan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Employee list
          Expanded(
            child: teamAttendanceAsync.when(
              data: (data) {
                if (data.employees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data karyawan',
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
                    ref.invalidate(teamAttendanceDetailProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    itemCount: data.employees.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingMD),
                    itemBuilder: (context, index) {
                      final employee = data.employees[index];
                      return EmployeeAttendanceCard(employee: employee);
                    },
                  ),
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                itemCount: 5,
                separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingMD),
                itemBuilder: (context, index) => SkeletonLoader(
                  height: 200,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              error: (error, stack) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(teamAttendanceDetailProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
