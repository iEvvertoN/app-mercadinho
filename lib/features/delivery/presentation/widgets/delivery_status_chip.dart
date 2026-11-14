import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/delivery_models.dart';

class DeliveryStatusChip extends StatelessWidget {
  const DeliveryStatusChip({super.key, required this.status, this.compact = false});

  final StopStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      StopStatus.pending => (AppColors.surfaceElevated, AppColors.textSecondary),
      StopStatus.onRoute => (AppColors.infoLight, AppColors.info),
      StopStatus.arrived => (AppColors.secondaryLight, const Color(0xFF92400E)),
      StopStatus.delivered => (AppColors.primaryLight, AppColors.primaryDark),
      StopStatus.failed => (AppColors.dangerLight, AppColors.danger),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        stopStatusLabel(status),
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
