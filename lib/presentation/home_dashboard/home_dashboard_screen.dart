import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/advanced_options_sheet_widget.dart';
import './widgets/monitoring_card_widget.dart';
import './widgets/quick_action_card_widget.dart';
import './widgets/sos_button_widget.dart';
import './widgets/status_badge_widget.dart';

class HomeDashboardInitialPage extends StatefulWidget {
  const HomeDashboardInitialPage({super.key});

  @override
  State<HomeDashboardInitialPage> createState() =>
      _HomeDashboardInitialPageState();
}

class _HomeDashboardInitialPageState extends State<HomeDashboardInitialPage> {
  bool isMonitoringActive = true;
  bool motionAIEnabled = true;
  bool audioAIEnabled = true;
  bool voiceShieldEnabled = true;
  double motionSensitivity = 0.7;
  double audioSensitivity = 0.6;
  bool isOnlineMode = true;
  bool isBatteryOptimized = true;

  void _showAdvancedOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedOptionsSheetWidget(
        motionSensitivity: motionSensitivity,
        audioSensitivity: audioSensitivity,
        onMotionSensitivityChanged: (value) {
          setState(() => motionSensitivity = value);
        },
        onAudioSensitivityChanged: (value) {
          setState(() => audioSensitivity = value);
        },
      ),
    );
  }

  Future<void> _refreshMonitoring() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isMonitoringActive = true;
      motionAIEnabled = true;
      audioAIEnabled = true;
      voiceShieldEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refreshMonitoring,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: isOnlineMode ? 'wifi' : 'wifi_off',
                      color: isOnlineMode
                          ? theme.colorScheme.primary
                          : AppTheme.warningColor,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      isOnlineMode ? 'Online' : 'SMS Only',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isOnlineMode
                            ? theme.colorScheme.primary
                            : AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: isBatteryOptimized
                          ? 'battery_charging_full'
                          : 'battery_alert',
                      color: isBatteryOptimized
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      isBatteryOptimized ? 'Optimized' : 'Check Settings',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isBatteryOptimized
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                children: [
                  StatusBadgeWidget(
                    isProtected:
                        motionAIEnabled && audioAIEnabled && voiceShieldEnabled,
                  ),
                  SizedBox(height: 3.h),
                  
                  SOSButtonWidget(
  isActive: true,
  onSwipeUp: () {
    // your swipe up logic (options / modal etc.)
  },
),

                  SizedBox(height: 4.h),
                  Text(
                    'Active Monitoring',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  MonitoringCardWidget(
                    title: 'Motion AI',
                    icon: 'directions_run',
                    isEnabled: motionAIEnabled,
                    sensitivity: motionSensitivity,
                    onToggle: (value) {
                      setState(() => motionAIEnabled = value);
                    },
                  ),
                  SizedBox(height: 2.h),
                  MonitoringCardWidget(
                    title: 'Audio AI',
                    icon: 'mic',
                    isEnabled: audioAIEnabled,
                    sensitivity: audioSensitivity,
                    onToggle: (value) {
                      setState(() => audioAIEnabled = value);
                    },
                  ),
                  SizedBox(height: 2.h),
                  MonitoringCardWidget(
                    title: 'VoiceShield',
                    icon: 'phone_in_talk',
                    isEnabled: voiceShieldEnabled,
                    sensitivity: 0.8,
                    onToggle: (value) {
                      setState(() => voiceShieldEnabled = value);
                    },
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionCardWidget(
                          icon: 'people',
                          title: 'Test Contacts',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Sending test alert to emergency contacts...',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: QuickActionCardWidget(
                          icon: 'location_on',
                          title: 'View Location',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening location view...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  QuickActionCardWidget(
                    icon: isOnlineMode ? 'cloud' : 'sms',
                    title: isOnlineMode
                        ? 'Switch to SMS Mode'
                        : 'Switch to Online Mode',
                    onTap: () {
                      setState(() => isOnlineMode = !isOnlineMode);
                    },
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
