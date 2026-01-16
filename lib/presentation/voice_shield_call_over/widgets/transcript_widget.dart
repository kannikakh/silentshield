import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Widget displaying call transcript with highlighted suspicious phrases
class TranscriptWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transcript;

  const TranscriptWidget({super.key, required this.transcript});

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
          Row(
            children: [
              CustomIconWidget(
                iconName: 'transcribe',
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Live Transcript',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            constraints: BoxConstraints(maxHeight: 30.h),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: transcript.length,
              separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
              itemBuilder: (context, index) {
                final entry = transcript[index];
                final isSuspicious = entry["isSuspicious"] as bool;
                final isUser = entry["speaker"] == "You";

                return Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isSuspicious
                        ? AppTheme.emergencyColor.withValues(alpha: 0.05)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: isSuspicious
                        ? Border.all(
                            color: AppTheme.emergencyColor.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry["speaker"] as String,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isUser
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            entry["timestamp"] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (isSuspicious) ...[
                            Spacer(),
                            CustomIconWidget(
                              iconName: 'warning',
                              color: AppTheme.emergencyColor,
                              size: 4.w,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        entry["text"] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
