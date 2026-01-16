import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

/// Reusable permission card widget for displaying permission details.
/// Supports expansion for detailed explanations and grant actions.
class PermissionCardWidget extends StatelessWidget {
  /// Icon name for the permission
  final String iconName;

  /// Title of the permission
  final String title;

  /// Brief description of the permission
  final String description;

  /// Detailed explanation shown when expanded
  final String detailedExplanation;

  /// Whether the permission is granted
  final bool isGranted;

  /// Whether this is a critical permission
  final bool isCritical;

  /// Whether the card is expanded
  final bool isExpanded;

  /// Callback when card is tapped
  final VoidCallback onTap;

  /// Callback when grant button is pressed
  final VoidCallback onGrant;

  const PermissionCardWidget({
    super.key,
    required this.iconName,
    required this.title,
    required this.description,
    required this.detailedExplanation,
    required this.isGranted,
    required this.isCritical,
    required this.isExpanded,
    required this.onTap,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppTheme.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        side: BorderSide(
          color: isGranted
              ? AppTheme.successColor
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isGranted ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon, title, and status
              Row(
                children: [
                  // Permission icon
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: isGranted
                          ? AppTheme.successColor.withValues(alpha: 0.1)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: iconName,
                      color: isGranted
                          ? AppTheme.successColor
                          : theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Title and critical badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCritical) ...[
                              SizedBox(width: 2.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.emergencyColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusSmall,
                                  ),
                                ),
                                child: Text(
                                  'CRITICAL',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.emergencyColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  // Status indicator
                  if (isGranted)
                    Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'check',
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  else
                    CustomIconWidget(
                      iconName: isExpanded ? 'expand_less' : 'expand_more',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                ],
              ),
              SizedBox(height: 1.5.h),
              // Description
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // Expanded detailed explanation
              if (isExpanded && !isGranted) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusMedium,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why we need this:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        detailedExplanation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onGrant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusMedium,
                              ),
                            ),
                          ),
                          child: Text(
                            'Grant Permission',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
