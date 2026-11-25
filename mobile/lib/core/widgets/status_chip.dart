import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

enum StatusType {
  present,      // Hadir
  onTime,       // Tepat waktu (alias untuk present)
  tolerance,    // Toleransi
  lateYellow,   // Telat kuning
  lateRed,      // Telat merah
  leave,        // Cuti
  sick,         // Sakit
  permission,   // Izin
  dinas,        // Dinas
  holiday,      // Libur
  absent,       // Alfa
  pending,      // Approval pending
  approved,     // Approved
  rejected,     // Rejected
  offline,      // Offline
}

class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type;
  final Color? customColor;
  final bool outline;
  final bool showDot;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
    this.customColor,
    this.outline = false,
    this.showDot = true,
    this.onTap,
  });

  Color _getColor(BuildContext context) {
    if (customColor != null) return customColor!;
    switch (type) {
      case StatusType.present:
      case StatusType.onTime:
        return AppColors.success;
      case StatusType.tolerance:
        return AppColors.tolerance;
      case StatusType.lateYellow:
        return AppColors.warningYellow;
      case StatusType.lateRed:
        return AppColors.error;
      case StatusType.leave:
        return AppColors.info;
      case StatusType.sick:
        return AppColors.purple;
      case StatusType.permission:
        return AppColors.cyan;
      case StatusType.dinas:
        return AppColors.teal;
      case StatusType.holiday:
        return AppColors.grey;
      case StatusType.absent:
        return AppColors.alpha;
      case StatusType.pending:
        return AppColors.pending;
      case StatusType.approved:
        return AppColors.success;
      case StatusType.rejected:
        return AppColors.error;
      case StatusType.offline:
        return AppColors.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    final bgColor = outline ? Colors.transparent : color.withValues(alpha: 0.14);
    final borderColor = outline ? color.withValues(alpha: 0.6) : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              if (type == StatusType.pending)
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: color,
                  ),
                )
              else
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
