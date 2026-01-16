import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StatusBadgeWidget extends StatelessWidget {
  final bool isProtected;

  const StatusBadgeWidget({super.key, required this.isProtected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: isProtected
            ? AppTheme.successColor.withValues(alpha: 0.1)
            : AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: isProtected ? AppTheme.successColor : AppTheme.warningColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: isProtected ? 'shield' : 'warning',
            color: isProtected ? AppTheme.successColor : AppTheme.warningColor,
            size: 24,
          ),
          SizedBox(width: 2.w),
          Text(
            isProtected ? 'Protected' : 'Limited Protection',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isProtected
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
