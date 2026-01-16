import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Widget displaying quick action buttons
class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onBlockNumber;
  final VoidCallback onReportScam;
  final VoidCallback onSaveEvidence;
  final VoidCallback onEndCall;

  const ActionButtonsWidget({
    super.key,
    required this.onBlockNumber,
    required this.onReportScam,
    required this.onSaveEvidence,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'Block',
                  icon: 'block',
                  color: AppTheme.emergencyColor,
                  onTap: onBlockNumber,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'Report',
                  icon: 'report',
                  color: AppTheme.warningColor,
                  onTap: onReportScam,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'Save',
                  icon: 'save',
                  color: theme.colorScheme.primary,
                  onTap: onSaveEvidence,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'End Call',
                  icon: 'call_end',
                  color: AppTheme.emergencyColor,
                  onTap: onEndCall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            children: [
              CustomIconWidget(iconName: icon, color: color, size: 6.w),
              SizedBox(height: 1.h),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
