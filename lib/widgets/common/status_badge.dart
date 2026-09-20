import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
  });

  factory StatusBadge.verification(String status) {
    switch (status) {
      case 'verified':
        return const StatusBadge(
          label: 'Verified',
          color: AppColors.success,
          icon: Icons.verified_outlined,
        );
      case 'rejected':
        return const StatusBadge(
          label: 'Rejected',
          color: AppColors.danger,
          icon: Icons.block_outlined,
        );
      default:
        return const StatusBadge(
          label: 'Pending',
          color: AppColors.warning,
          icon: Icons.hourglass_top_outlined,
        );
    }
  }

  factory StatusBadge.urgency(String urgency) {
    switch (urgency) {
      case 'critical':
        return const StatusBadge(
          label: 'Critical',
          color: AppColors.danger,
          icon: Icons.warning_amber_outlined,
        );
      case 'high':
        return const StatusBadge(
          label: 'High',
          color: AppColors.secondary,
          icon: Icons.priority_high_outlined,
        );
      case 'medium':
        return const StatusBadge(
          label: 'Medium',
          color: AppColors.warning,
          icon: Icons.flag_outlined,
        );
      default:
        return const StatusBadge(
          label: 'Low',
          color: AppColors.textMuted,
          icon: Icons.flag_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: small ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
