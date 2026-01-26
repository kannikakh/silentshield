import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/app_export.dart';
import './widgets/permission_card_widget.dart';

/// Permissions Setup screen for SilentShield application.
/// Guides users through essential permission grants using card-based layout.
class PermissionsSetup extends StatefulWidget {
  const PermissionsSetup({super.key});

  @override
  State<PermissionsSetup> createState() => _PermissionsSetupState();
}

class _PermissionsSetupState extends State<PermissionsSetup> {
  // ✅ Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Permission status tracking
  final Map<String, bool> _permissionStatus = {
    'location': false,
    'microphone': false,
    'motion': false,
    'phone': false,
    'sms': false,
  };

  // Track expanded card
  String? _expandedCard;

  @override
  void initState() {
    super.initState();
    _checkExistingPermissions();
  }

  /// Check existing permission status on screen load
  Future<void> _checkExistingPermissions() async {
    final locationStatus = await Permission.location.status;
    final microphoneStatus = await Permission.microphone.status;
    final phoneStatus = await Permission.phone.status;
    final smsStatus = await Permission.sms.status;
    final sensorsStatus = await Permission.sensors.status;

    setState(() {
      _permissionStatus['location'] = locationStatus.isGranted;
      _permissionStatus['microphone'] = microphoneStatus.isGranted;
      _permissionStatus['phone'] = phoneStatus.isGranted;
      _permissionStatus['sms'] = smsStatus.isGranted;
      _permissionStatus['motion'] = sensorsStatus.isGranted;
    });
  }

  // ✅ Store user location into Firestore (only lat,lng,mapLink,timeStamp)
  Future<void> _storeUserLocationToFirestore() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        debugPrint("❌ User not logged in - cannot store location");
        return;
      }

      // ✅ Ensure location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("❌ Location service disabled");
        return;
      }

      // ✅ Get GPS position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final mapLink =
          "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";

      // ✅ Store for each user (inside Users/{uid}/locations)
      await _firestore
          .collection("Users")
          .doc(user.uid)
          .collection("locations")
          .add({
            "lat": pos.latitude,
            "lng": pos.longitude,
            "mapLink": mapLink,
            "timeStamp": FieldValue.serverTimestamp(),
          });

      debugPrint("✅ Location stored in Firestore for user: ${user.uid}");
    } catch (e) {
      debugPrint("❌ Firestore location save failed: $e");
    }
  }

  /// Request specific permission
  Future<void> _requestPermission(String permissionType) async {
    Permission permission;

    switch (permissionType) {
      case 'location':
        permission = Permission.location;
        break;
      case 'microphone':
        permission = Permission.microphone;
        break;
      case 'phone':
        permission = Permission.phone;
        break;
      case 'sms':
        permission = Permission.sms;
        break;
      case 'motion':
        permission = Permission.sensors;
        break;
      default:
        return;
    }

    final status = await permission.request();

    // ✅ If location permission granted → store location immediately
    if (permissionType == "location" && status.isGranted) {
      await _storeUserLocationToFirestore();
    }

    setState(() {
      _permissionStatus[permissionType] = status.isGranted;
      _expandedCard = null;
    });

    if (status.isPermanentlyDenied) {
      _showSettingsDialog(permissionType);
    }
  }

  /// Show dialog to redirect to settings for permanently denied permissions
  void _showSettingsDialog(String permissionType) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required', style: theme.textTheme.titleLarge),
        content: Text(
          'This permission has been permanently denied. Please enable it in app settings to ensure full safety capabilities.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: theme.textTheme.labelLarge),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings', style: theme.textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  /// Show warning modal for skipping permissions
  void _showSkipWarningModal() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reduced Safety Capabilities',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.warningColor,
          ),
        ),
        content: Text(
          'Skipping critical permissions will significantly reduce SilentShield\'s ability to protect you in emergency situations. Are you sure you want to continue?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go Back', style: theme.textTheme.labelLarge),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed('/authentication');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: Text('Continue Anyway', style: theme.textTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  /// Check if critical permissions are granted
  bool get _criticalPermissionsGranted {
    return _permissionStatus['location'] == true &&
        _permissionStatus['microphone'] == true &&
        _permissionStatus['motion'] == true;
  }

  /// Calculate progress percentage
  double get _progressPercentage {
    final grantedCount = _permissionStatus.values
        .where((granted) => granted)
        .length;
    return grantedCount / _permissionStatus.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky header with title and progress
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'arrow_back',
                          color: theme.colorScheme.onSurface,
                          size: 24,
                        ),
                        onPressed: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed('/onboarding-flow'),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Safety Permissions Required',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),

                  // Progress indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(_progressPercentage * 100).toInt()}% Complete',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${_permissionStatus.values.where((granted) => granted).length}/${_permissionStatus.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                        child: LinearProgressIndicator(
                          value: _progressPercentage,
                          minHeight: 0.6.h,
                          backgroundColor: theme.colorScheme.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _criticalPermissionsGranted
                                ? AppTheme.successColor
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable permission cards
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  children: [
                    PermissionCardWidget(
                      iconName: 'location_on',
                      title: 'Location Services',
                      description:
                          'Enable GPS tracking for real-time location sharing during emergencies',
                      detailedExplanation:
                          'SilentShield uses your location to:\n• Share your exact position with emergency contacts\n• Track your movement during SOS activation\n• Provide location history for safety verification\n• Enable offline SMS with location coordinates',
                      isGranted: _permissionStatus['location'] ?? false,
                      isCritical: true,
                      isExpanded: _expandedCard == 'location',
                      onTap: () {
                        setState(() {
                          _expandedCard = _expandedCard == 'location'
                              ? null
                              : 'location';
                        });
                      },
                      onGrant: () => _requestPermission('location'),
                    ),
                    SizedBox(height: 2.h),
                    PermissionCardWidget(
                      iconName: 'mic',
                      title: 'Microphone Access',
                      description:
                          'Detect voice triggers and record audio evidence during emergencies',
                      detailedExplanation:
                          'SilentShield uses your microphone to:\n• Detect silent SOS voice keywords\n• Record audio evidence during emergencies\n• Enable VoiceShield scam call analysis\n• Capture ambient sound for safety verification',
                      isGranted: _permissionStatus['microphone'] ?? false,
                      isCritical: true,
                      isExpanded: _expandedCard == 'microphone',
                      onTap: () {
                        setState(() {
                          _expandedCard = _expandedCard == 'microphone'
                              ? null
                              : 'microphone';
                        });
                      },
                      onGrant: () => _requestPermission('microphone'),
                    ),
                    SizedBox(height: 2.h),
                    PermissionCardWidget(
                      iconName: 'sensors',
                      title: 'Motion Sensors',
                      description:
                          'Enable silent SOS detection through device movement patterns',
                      detailedExplanation:
                          'SilentShield uses motion sensors to:\n• Detect shake patterns for silent SOS\n• Monitor unusual movement during emergencies\n• Trigger automatic alerts on sudden impacts\n• Verify user safety through motion analysis',
                      isGranted: _permissionStatus['motion'] ?? false,
                      isCritical: true,
                      isExpanded: _expandedCard == 'motion',
                      onTap: () {
                        setState(() {
                          _expandedCard = _expandedCard == 'motion'
                              ? null
                              : 'motion';
                        });
                      },
                      onGrant: () => _requestPermission('motion'),
                    ),
                    SizedBox(height: 2.h),
                    PermissionCardWidget(
                      iconName: 'phone',
                      title: 'Phone Access',
                      description:
                          'Enable VoiceShield call screening and scam detection',
                      detailedExplanation:
                          'SilentShield uses phone access to:\n• Screen incoming calls for scam detection\n• Display real-time risk analysis during calls\n• Block suspicious numbers automatically\n• Generate call transcripts and summaries',
                      isGranted: _permissionStatus['phone'] ?? false,
                      isCritical: false,
                      isExpanded: _expandedCard == 'phone',
                      onTap: () {
                        setState(() {
                          _expandedCard = _expandedCard == 'phone'
                              ? null
                              : 'phone';
                        });
                      },
                      onGrant: () => _requestPermission('phone'),
                    ),
                    SizedBox(height: 2.h),
                    PermissionCardWidget(
                      iconName: 'sms',
                      title: 'SMS Functionality',
                      description:
                          'Send emergency alerts when internet connection is unavailable',
                      detailedExplanation:
                          'SilentShield uses SMS to:\n• Send emergency alerts without internet\n• Share location coordinates via text\n• Notify contacts during network outages\n• Provide offline emergency communication',
                      isGranted: _permissionStatus['sms'] ?? false,
                      isCritical: false,
                      isExpanded: _expandedCard == 'sms',
                      onTap: () {
                        setState(() {
                          _expandedCard = _expandedCard == 'sms' ? null : 'sms';
                        });
                      },
                      onGrant: () => _requestPermission('sms'),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),

            // Bottom sticky section with continue button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _criticalPermissionsGranted
                          ? () => Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushNamed('/authentication')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _criticalPermissionsGranted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        foregroundColor: _criticalPermissionsGranted
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusMedium,
                          ),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  TextButton(
                    onPressed: _showSkipWarningModal,
                    child: Text(
                      'Skip for Now',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
