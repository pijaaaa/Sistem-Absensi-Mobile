import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/skeleton_loader.dart';
import 'package:mobile/core/widgets/error_state.dart';
import 'package:mobile/features/attendance/presentation/providers/summary_providers.dart';
import 'package:mobile/core/models/attendance_summary_models.dart';

class TeamStatsSection extends ConsumerWidget {
  const TeamStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final teamStatsAsync = ref.watch(teamStatsProvider);

    return teamStatsAsync.when(
      data: (stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Tim Hari Ini',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Hadir',
                  value: '${stats.presentToday}',
                  total: '${stats.totalEmployees}',
                  color: AppColors.success,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Telat',
                  value: '${stats.lateToday}',
                  total: '${stats.totalEmployees}',
                  color: AppColors.warningYellow,
                  icon: Icons.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Belum Absen',
                  value: '${stats.notCheckedIn}',
                  total: '${stats.totalEmployees}',
                  color: AppColors.error,
                  icon: Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Pie Chart
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Persentase Kehadiran Tim',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                color: AppColors.success,
                                value: stats.presentToday.toDouble(),
                                title: '${stats.presentToday}',
                                radius: 45,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: AppColors.warningYellow,
                                value: stats.lateToday.toDouble(),
                                title: '${stats.lateToday}',
                                radius: 40,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: AppColors.error,
                                value: stats.notCheckedIn.toDouble(),
                                title: '${stats.notCheckedIn}',
                                radius: 35,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem(context, 'Hadir', AppColors.success),
                            const SizedBox(height: 8),
                            _buildLegendItem(context, 'Telat', AppColors.warningYellow),
                            const SizedBox(height: 8),
                            _buildLegendItem(context, 'Belum Absen', AppColors.error),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (stats.lateEmployees.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Daftar Karyawan Telat',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...stats.lateEmployees.map((emp) => ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.warningYellow,
                    child: Icon(Icons.warning, size: 16, color: Colors.white),
                  ),
                  title: Text(emp.name),
                  subtitle: Text('Jam masuk: ${emp.checkIn ?? '-'}'),
                  trailing: Text(
                    '${emp.lateMinutes ?? 0} mnt',
                    style: const TextStyle(
                      color: AppColors.warningYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
          ],
        ],
      ),
      loading: () => SkeletonLoader(height: 250, borderRadius: BorderRadius.circular(20)),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(teamStatsProvider),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String total,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                '$value/$total',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
