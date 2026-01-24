import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/app_export.dart';
import './widgets/active_services_panel.dart';
import './widgets/emergency_contact_status_card.dart';

class SosActivated extends StatefulWidget {
  const SosActivated({super.key});

  @override
  State<SosActivated> createState() => _SosActivatedState();
}

class _SosActivatedState extends State<SosActivated>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // Controllers and state
  GoogleMapController? _mapController;
  late AnimationController _pulseController;
  late AnimationController _radiusController;
  Timer? _locationUpdateTimer;
  Timer? _elapsedTimeTimer;
  Timer? _hapticTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Location and map state
  LatLng _currentLocation = const LatLng(
    37.7749,
    -122.4194,
  ); // Default San Francisco
  double _gpsAccuracy = 0.0;
  bool _isLocationServiceActive = true;
  bool _isSmsActive = false;
  bool _isRecordingEvidence = false;
  Set<Circle> _circles = {};

  // Timer state
  Duration _elapsedTime = Duration.zero;

  // Emergency contacts mock data
  final List<Map<String, dynamic>> _emergencyContacts = [
    {
      "name": "Sarah Johnson",
      "relation": "Emergency Contact 1",
      "status": "delivered",
      "timestamp": DateTime.now().subtract(const Duration(seconds: 5)),
    },
    {
      "name": "Michael Chen",
      "relation": "Emergency Contact 2",
      "status": "delivered",
      "timestamp": DateTime.now().subtract(const Duration(seconds: 8)),
    },
    {
      "name": "Emma Williams",
      "relation": "Emergency Contact 3",
      "status": "pending",
      "timestamp": DateTime.now(),
    },
  ];

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _initializeEmergencyMode();
}
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}


  Future<void> _initializeEmergencyMode() async {
    // Lock screen orientation to portrait

    // Prevent device sleep and set maximum brightness
    WakelockPlus.enable();

    // Initialize animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _radiusController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Start location updates
    _startLocationUpdates();

    // Start elapsed time counter
    _startElapsedTimeCounter();

    // Start haptic feedback timer (every 30 seconds)
    _startHapticFeedback();

    // Start evidence recording
    await _startEvidenceRecording();

    // Check network connectivity
    _checkNetworkStatus();
  }

  void _startLocationUpdates() {
    _updateLocation();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _gpsAccuracy = position.accuracy;
        _isLocationServiceActive = true;

        // Update expanding radius circle
        _circles = {
          Circle(
            circleId: const CircleId('broadcast_radius'),
            center: _currentLocation,
            radius: 100 + (_radiusController.value * 400),
            fillColor: AppTheme.emergencyColor.withValues(alpha: 0.1),
            strokeColor: AppTheme.emergencyColor.withValues(alpha: 0.3),
            strokeWidth: 2,
          ),
        };
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation));
    } catch (e) {
      setState(() {
        _isLocationServiceActive = false;
      });
    }
  }

  void _startElapsedTimeCounter() {
    _elapsedTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
      });
    });
  }

  void _startHapticFeedback() {
    _hapticTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 200);
      }
    });
  }

  Future<void> _startEvidenceRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(),
          path: 'emergency_evidence.m4a',
        );
        setState(() {
          _isRecordingEvidence = true;
        });
      }
    } catch (e) {
      setState(() {
        _isRecordingEvidence = false;
      });
    }
  }

  void _checkNetworkStatus() {
    // Simulate network check - in production, use connectivity_plus
    setState(() {
      _isSmsActive = false; // Will be true if network is unavailable
    });
  }

  String _formatElapsedTime() {
    final hours = _elapsedTime.inHours.toString().padLeft(2, '0');
    final minutes = (_elapsedTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_elapsedTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _showCancelEmergencyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _CancelEmergencyDialog(onPinVerified: _cancelEmergency),
    );
  }

  void _cancelEmergency() async {
    // Stop all services
    _locationUpdateTimer?.cancel();
    _elapsedTimeTimer?.cancel();
    _hapticTimer?.cancel();
    await _audioRecorder.stop();
    WakelockPlus.disable();

    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/home-dashboard');
    }
  }

  void _showVoiceNoteRecorder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VoiceNoteRecorder(
        onRecordingComplete: (path) {
          // Handle voice note
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice note added to emergency alert'),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {

    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _radiusController.dispose();
    _locationUpdateTimer?.cancel();
    _elapsedTimeTimer?.cancel();
    _hapticTimer?.cancel();
    _audioRecorder.dispose();
    _mapController?.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        backgroundColor: AppTheme.emergencyColor,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.emergencyColor.withValues(
                    alpha: 0.9 + (_pulseController.value * 0.1),
                  ),
                ),
                child: child,
              );
            },
            child: Column(
              children: [
                _buildHeader(theme),
                _buildTimerSection(theme),
                _buildMapSection(),
                _buildContactStatusSection(theme),
                _buildActionButtons(theme),
                _buildActiveServicesSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EMERGENCY ACTIVE',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: _isLocationServiceActive
                        ? 'gps_fixed'
                        : 'gps_off',
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _isLocationServiceActive
                        ? 'GPS Active (±${_gpsAccuracy.toStringAsFixed(0)}m)'
                        : 'GPS Unavailable',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isSmsActive)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'sms',
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'SMS MODE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
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

  Widget _buildTimerSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        children: [
          Text(
            'ELAPSED TIME',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _formatElapsedTime(),
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 48,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AnimatedBuilder(
            animation: _radiusController,
            builder: (context, child) {
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                circles: _circles,
                markers: {
                  Marker(
                    markerId: const MarkerId('current_location'),
                    position: _currentLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
                  ),
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContactStatusSection(ThemeData theme) {
    return Container(
      height: 20.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMERGENCY CONTACTS NOTIFIED',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 1.h),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emergencyContacts.length,
              separatorBuilder: (context, index) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                return EmergencyContactStatusCard(
                  contact: _emergencyContacts[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
  behavior: HitTestBehavior.opaque,
  onLongPress: () {
    HapticFeedback.lightImpact();
    _showCancelEmergencyDialog();
  },
  onLongPressStart: (_) {},
  onLongPressMoveUpdate: (_) {},
  onLongPressEnd: (_) {},
  child: Container(

                height: 7.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'LONG PRESS TO CANCEL',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.emergencyColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _showVoiceNoteRecorder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'mic',
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'VOICE NOTE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveServicesSection(ThemeData theme) {
    return ActiveServicesPanel(
      isLocationActive: _isLocationServiceActive,
      isSmsActive: _isSmsActive,
      isRecordingEvidence: _isRecordingEvidence,
    );
  }
}

class _CancelEmergencyDialog extends StatefulWidget {
  final VoidCallback onPinVerified;

  const _CancelEmergencyDialog({required this.onPinVerified});

  @override
  State<_CancelEmergencyDialog> createState() => _CancelEmergencyDialogState();
}

class _CancelEmergencyDialogState extends State<_CancelEmergencyDialog> {
  final TextEditingController _pinController = TextEditingController();
  Timer? _timeoutTimer;
  int _remainingSeconds = 30;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  void _startTimeout() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          Navigator.of(context).pop();
        }
      });
    });
  }

  void _verifyPin() {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // Mock PIN verification - in production, verify against stored PIN
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_pinController.text == '1234') {
        _timeoutTimer?.cancel();
        Navigator.of(context).pop();
        widget.onPinVerified();
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Incorrect PIN. Try again.';
          _pinController.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    
    _timeoutTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enter Emergency PIN',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_remainingSeconds}s',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Pinput(
              controller: _pinController,
              length: 4,
              autofocus: true,
              obscureText: true,
              enabled: !_isVerifying,
              onCompleted: (pin) => _verifyPin(),
              defaultPinTheme: PinTheme(
                width: 15.w,
                height: 8.h,
                textStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 15.w,
                height: 8.h,
                textStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              errorPinTheme: PinTheme(
                width: 15.w,
                height: 8.h,
                textStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorLight,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: AppTheme.errorLight, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 2.h),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.errorLight,
                ),
              ),
            ],
            SizedBox(height: 3.h),
            Text(
              'Mock PIN: 1234',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyPin,
                    child: _isVerifying
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Text('Verify'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceNoteRecorder extends StatefulWidget {
  final Function(String) onRecordingComplete;

  const _VoiceNoteRecorder({required this.onRecordingComplete});

  @override
  State<_VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<_VoiceNoteRecorder> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      _durationTimer?.cancel();
      if (path != null) {
        widget.onRecordingComplete(path);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } else {
      if (await _recorder.hasPermission()) {
        await _recorder.start(const RecordConfig(), path: 'voice_note.m4a');
        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration = Duration(
              seconds: _recordingDuration.inSeconds + 1,
            );
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Record Voice Note',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          if (_isRecording) ...[
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.emergencyColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'mic',
                color: AppTheme.emergencyColor,
                size: 48,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '${_recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'mic_none',
                color: theme.colorScheme.primary,
                size: 48,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Tap to start recording',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _toggleRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording
                        ? AppTheme.emergencyColor
                        : theme.colorScheme.primary,
                  ),
                  child: Text(_isRecording ? 'Stop' : 'Record'),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
