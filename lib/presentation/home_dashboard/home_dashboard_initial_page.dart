import 'package:flutter/material.dart';

// imported widgets live under presentation/home_dashboard/widgets/
import 'widgets/monitoring_card.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/sos_button.dart';
import 'widgets/status_badge.dart';
import '../../routes/app_routes.dart';

class HomeDashboardInitialPage extends StatefulWidget {
  const HomeDashboardInitialPage({Key? key}) : super(key: key);

  @override
  State<HomeDashboardInitialPage> createState() =>
      _HomeDashboardInitialPageState();
}

class _HomeDashboardInitialPageState extends State<HomeDashboardInitialPage> {
  bool _motionEnabled = true;
  bool _audioEnabled = true;
  bool _voiceShieldEnabled = true;

  void _openVoiceNoteRecorder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Record Voice Note',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Icon(Icons.mic, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('Tap to start recording', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Record'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Top row: spacer + settings
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.settings),
                      icon: Icon(
                        Icons.settings,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                // Protected badge
                Align(
                  alignment: Alignment.center,
                  child: StatusBadge(protected: true),
                ),
                const SizedBox(height: 12),

                // Big SOS button
                Center(
                  child: Column(
                    children: [
                      const SosButton(),
                      const SizedBox(height: 8),
                      // small voice note button under SOS
                      IconButton(
                        onPressed: _openVoiceNoteRecorder,
                        icon: Icon(Icons.mic, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Long press to activate',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 18),

                // Active Monitoring header
                Text(
                  'Active Monitoring',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Monitoring cards
                MonitoringCard(
                  title: 'Motion AI',
                  icon: Icons.directions_run,
                  percent: 0.7,
                  value: _motionEnabled,
                  onChanged: (v) => setState(() => _motionEnabled = v),
                ),
                const SizedBox(height: 12),
                MonitoringCard(
                  title: 'Audio AI',
                  icon: Icons.mic,
                  percent: 0.6,
                  value: _audioEnabled,
                  onChanged: (v) => setState(() => _audioEnabled = v),
                ),
                const SizedBox(height: 12),
                MonitoringCard(
                  title: 'VoiceShield',
                  icon: Icons.call,
                  percent: 0.8,
                  value: _voiceShieldEnabled,
                  onChanged: (v) => setState(() => _voiceShieldEnabled = v),
                ),

                const SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Quick action grid
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        label: 'Test Contacts',
                        icon: Icons.group,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.contacts),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QuickActionCard(
                        label: 'View Location',
                        icon: Icons.location_on,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.activity),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: QuickActionCard(
                    label: 'Switch to SMS Mode',
                    icon: Icons.cloud,
                    wide: true,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
