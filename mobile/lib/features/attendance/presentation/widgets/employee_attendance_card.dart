import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/features/attendance/data/models/team_attendance_detail_model.dart';

class EmployeeAttendanceCard extends StatelessWidget {
  final EmployeeAttendanceDetail employee;

  const EmployeeAttendanceCard({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAttendance = employee.hasCheckedIn;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nama karyawan
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: hasAttendance ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                child: Icon(
                  hasAttendance ? Icons.check_circle : Icons.access_time,
                  color: hasAttendance ? AppColors.success : AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: ${employee.employeeId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (hasAttendance) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Check-in info
            _buildInfoRow(
              context,
              icon: Icons.login,
              label: 'Check In',
              value: employee.checkInAt ?? '-',
              iconColor: AppColors.success,
            ),
            const SizedBox(height: 12),

            // Check-out info
            _buildInfoRow(
              context,
              icon: Icons.logout,
              label: 'Check Out',
              value: employee.checkOutAt ?? 'Belum checkout',
              iconColor: employee.hasCheckedOut ? AppColors.info : AppColors.warningYellow,
            ),
            const SizedBox(height: 12),

            // Lokasi
            if (employee.locationName != null) ...[
              _buildInfoRow(
                context,
                icon: Icons.location_on,
                label: 'Lokasi',
                value: employee.locationName!,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 12),
            ] else if (employee.inLat != null && employee.inLng != null) ...[
              _buildInfoRow(
                context,
                icon: Icons.location_on,
                label: 'Koordinat',
                value: '${employee.inLat!.toStringAsFixed(6)}, ${employee.inLng!.toStringAsFixed(6)}',
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 12),
            ],

            // Badges row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Device badge
                _buildBadge(
                  context,
                  label: employee.isBackupDevice ? 'Device Secondary' : 'Device Primary',
                  color: employee.isBackupDevice ? AppColors.warningYellow : AppColors.success,
                ),
                
                // Late badge
                if (employee.isLate)
                  _buildBadge(
                    context,
                    label: 'Telat ${employee.lateMinutes} menit',
                    color: AppColors.error,
                  ),
                
                // Approval status badge
                if (employee.approvalStatus != null)
                  _buildBadge(
                    context,
                    label: _getApprovalLabel(employee.approvalStatus!),
                    color: _getApprovalColor(employee.approvalStatus!),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Belum melakukan absensi',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, {required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _getApprovalLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
        return 'Menunggu';
      default:
        return status;
    }
  }

  Color _getApprovalColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warningYellow;
      default:
        return AppColors.info;
    }
  }
}
