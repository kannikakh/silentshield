import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/call_info_widget.dart';
import './widgets/risk_meter_widget.dart';
import './widgets/scam_patterns_widget.dart';
import './widgets/transcript_widget.dart';

/// VoiceShield Call Overlay Screen
/// Provides real-time scam protection through floating interface during active phone calls
class VoiceShieldCallOverlay extends StatefulWidget {
  const VoiceShieldCallOverlay({super.key});

  @override
  State<VoiceShieldCallOverlay> createState() => _VoiceShieldCallOverlayState();
}

class _VoiceShieldCallOverlayState extends State<VoiceShieldCallOverlay>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  Offset _position = Offset(80.w, 20.h);
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Mock call data
  final Map<String, dynamic> _callData = {
    "callerName": "Unknown Caller",
    "callerNumber": "+1 (555) 123-4567",
    "callDuration": "00:45",
    "riskPercentage": 85,
    "riskLevel": "High Risk",
    "isScamLikely": true,
    "detectedPatterns": [
      "Urgency tactics detected",
      "Requesting personal information",
      "Financial pressure language",
      "Impersonation attempt",
    ],
    "transcript": [
      {
        "speaker": "Caller",
        "text":
            "This is the IRS calling about your unpaid taxes. You need to pay immediately or face legal action.",
        "timestamp": "00:12",
        "isSuspicious": true,
      },
      {
        "speaker": "You",
        "text": "I don't understand. Can you provide more details?",
        "timestamp": "00:28",
        "isSuspicious": false,
      },
      {
        "speaker": "Caller",
        "text":
            "We need your social security number to verify your identity right now.",
        "timestamp": "00:35",
        "isSuspicious": true,
      },
    ],
    "analysisStatus": "Analyzing in real-time...",
    "confidenceScore": 92,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getRiskColor() {
    final risk = _callData["riskPercentage"] as int;
    if (risk <= 30) {
      return AppTheme.successColor;
    } else if (risk <= 70) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.emergencyColor;
    }
  }

  String _getRiskLabel() {
    final risk = _callData["riskPercentage"] as int;
    if (risk <= 30) {
      return "Safe";
    } else if (risk <= 70) {
      return "Suspicious";
    } else {
      return "Likely Scam";
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _handleBlockNumber() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Number blocked and added to blacklist'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleReportScam() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scam reported to authorities'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSaveEvidence() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Call evidence saved to vault'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleEndCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Call'),
        content: Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed('/home-dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emergencyColor,
            ),
            child: Text('End Call'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBubble(ThemeData theme) {
    final riskColor = _getRiskColor();
    final riskPercentage = _callData["riskPercentage"] as int;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: _toggleExpanded,
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(0.0, 90.w),
              (_position.dy + details.delta.dy).clamp(0.0, 85.h),
            );
          });
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  color: riskColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: riskColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$riskPercentage%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      CustomIconWidget(
                        iconName: 'shield',
                        color: Colors.white,
                        size: 5.w,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpandedOverlay(ThemeData theme) {
    return Container(
      width: 100.w,
      height: 100.h,
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildExpandedHeader(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CallInfoWidget(callData: _callData),
                    SizedBox(height: 2.h),
                    RiskMeterWidget(
                      riskPercentage: _callData["riskPercentage"] as int,
                      riskLevel: _callData["riskLevel"] as String,
                      confidenceScore: _callData["confidenceScore"] as int,
                    ),
                    SizedBox(height: 2.h),
                    ScamPatternsWidget(
                      patterns: (_callData["detectedPatterns"] as List)
                          .map((e) => e as String)
                          .toList(),
                    ),
                    SizedBox(height: 2.h),
                    TranscriptWidget(
                      transcript: (_callData["transcript"] as List)
                          .map((e) => e as Map<String, dynamic>)
                          .toList(),
                    ),
                    SizedBox(height: 2.h),
                    ActionButtonsWidget(
                      onBlockNumber: _handleBlockNumber,
                      onReportScam: _handleReportScam,
                      onSaveEvidence: _handleSaveEvidence,
                      onEndCall: _handleEndCall,
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outline, width: 1),
              ),
              child: CustomIconWidget(
                iconName: 'keyboard_arrow_down',
                color: theme.colorScheme.onSurface,
                size: 6.w,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VoiceShield Active',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _callData["analysisStatus"] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: _getRiskColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'warning',
                  color: _getRiskColor(),
                  size: 4.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  _getRiskLabel(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _getRiskColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (!_isExpanded) _buildCompactBubble(theme),
          if (_isExpanded) _buildExpandedOverlay(theme),
        ],
      ),
    );
  }
}
