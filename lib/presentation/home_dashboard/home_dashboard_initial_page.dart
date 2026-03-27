import 'package:flutter/material.dart';

// existing widgets
import 'widgets/monitoring_card.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/sos_button.dart';
import 'widgets/status_badge.dart';
import '../../routes/app_routes.dart';

// AI + widgets
import '../../services/ai_service.dart';
import '../../widgets/transcript_widget.dart';
import '../../widgets/risk_meter_widget.dart';

class HomeDashboardInitialPage extends StatefulWidget {
  const HomeDashboardInitialPage({super.key});

  @override
  State<HomeDashboardInitialPage> createState() =>
      _HomeDashboardInitialPageState();
}

class _HomeDashboardInitialPageState extends State<HomeDashboardInitialPage> {
  bool _motionEnabled = true;
  bool _audioEnabled = true;
  bool _voiceShieldEnabled = true;

  String _transcript = "";
  double _risk = 0.0;
  String _label = "safe";
  bool _loading = false;

  void _runVoiceShieldTest() async {
    if (!_voiceShieldEnabled || !_audioEnabled) return;

    final samples = [
      "your account is blocked share otp",
      "you won a prize click link",
      "hello how are you",
    ];

    samples.shuffle();
    final testText = samples.first;

    try {
      setState(() {
        _loading = true;
        _transcript = "";
      });

      for (int i = 0; i < testText.length; i++) {
        await Future.delayed(const Duration(milliseconds: 25));
        setState(() {
          _transcript += testText[i];
        });
      }

      final result = await AIService.analyzeText(testText);

      setState(() {
        _risk = result["risk"];
        _label = result["label"];
        _loading = false;
      });

      if (_risk >= 0.7) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("⚠️ Scam call detected!"),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error connecting to AI service")),
      );
    }
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

                // 🔹 Top bar
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

                // 🔹 Status
                Align(
                  alignment: Alignment.center,
                  child: StatusBadge(protected: true),
                ),
                const SizedBox(height: 12),

                // 🔴 SOS + MIC
                Center(
                  child: Column(
                    children: [
                      const SosButton(),
                      const SizedBox(height: 8),

                      IconButton(
                        onPressed: _runVoiceShieldTest,
                        icon: Icon(
                          Icons.mic,
                          size: 28,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tap mic to analyze call',
                    style: theme.textTheme.bodySmall,
                  ),
                ),

                const SizedBox(height: 18),

                // 🔹 Monitoring
                Text(
                  'Active Monitoring',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

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

                // 🔥 AI OUTPUT
                if (_voiceShieldEnabled) ...[
                  Text(
                    'VoiceShield Analysis',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  if (_loading) const CircularProgressIndicator(),

                  TranscriptWidget(
                    text: _transcript.isEmpty
                        ? "Tap mic to analyze voice..."
                        : _transcript,
                  ),

                  RiskMeterWidget(risk: _risk, label: _label),
                ],

                const SizedBox(height: 20),

                // 🔹 Quick Actions
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

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

                // ✅ FINAL FIXED BUTTON
                Center(
                  child: QuickActionCard(
                    label: 'Live Call Analysis',
                    icon: Icons.call,
                    wide: true,
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/live-call-analysis');
                    },
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