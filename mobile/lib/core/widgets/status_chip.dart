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
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    required this.type,
    this.customColor,
    this.outline = false,
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
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    final textColor = _getTextColor(color);
    final bgColor = outline
        ? Colors.transparent
        : color.withOpacity(0.15);
    final borderColor = outline
        ? color
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == StatusType.pending && !outline)
              const SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: outline ? color : textColor,
              ),
            ),
          ],
        ),
      ));
  }

  Color _getTextColor(Color bgColor) {
    final luminance = (0.299 * bgColor.red +
            0.587 * bgColor.green +
            0.114 * bgColor.blue) /
        255;
    return luminance > 0.5 ? const Color(0xFF0B1330) : Colors.white;
  }
}
