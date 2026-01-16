import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActiveServicesPanel extends StatelessWidget {
  final bool isLocationActive;
  final bool isSmsActive;
  final bool isRecordingEvidence;

  const ActiveServicesPanel({
    super.key,
    required this.isLocationActive,
    required this.isSmsActive,
    required this.isRecordingEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE SERVICES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildServiceIndicator(
                theme: theme,
                icon: 'location_on',
                label: 'Location\nSharing',
                isActive: isLocationActive,
              ),
              _buildServiceIndicator(
                theme: theme,
                icon: 'sms',
                label: 'SMS\nFallback',
                isActive: isSmsActive,
              ),
              _buildServiceIndicator(
                theme: theme,
                icon: 'fiber_manual_record',
                label: 'Evidence\nRecording',
                isActive: isRecordingEvidence,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceIndicator({
    required ThemeData theme,
    required String icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.successColor.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? AppTheme.successColor
                  : Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: CustomIconWidget(
            iconName: icon,
            color: isActive
                ? AppTheme.successColor
                : Colors.white.withValues(alpha: 0.6),
            size: 24,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
