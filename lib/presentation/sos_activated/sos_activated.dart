import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/app_export.dart';
import '../../services/sos_sms_service.dart';

import './widgets/active_services_panel.dart';
import './widgets/emergency_contact_status_card.dart';

class SosActivated extends StatefulWidget {
  const SosActivated({super.key});

  @override
  State<SosActivated> createState() => _SosActivatedState();
}

class _SosActivatedState extends State<SosActivated>
    with TickerProviderStateMixin {
  // ---------------- FIREBASE ----------------
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _sosRef =>
      _firestore.collection("Users").doc(_uid).collection("sos_logs");

  String? _sosDocId;

  // ✅ STATIC NUMBERS (HARDCODED)
  final List<String> _staticEmergencyNumbers = [
    "+918072871278",
    "+919245581983",
    "+918124899091",
  ];

  // ✅ UI Contact cards (optional)
  late List<Map<String, dynamic>> _staticContactsUI;

  // ---------------- Controllers and state ----------------
  GoogleMapController? _mapController;
  late AnimationController _pulseController;
  late AnimationController _radiusController;

  Timer? _locationUpdateTimer;
  Timer? _elapsedTimeTimer;
  Timer? _hapticTimer;

  // ✅ Only ONE recorder (auto start when SOS activates)
  final AudioRecorder _evidenceRecorder = AudioRecorder();

  // ---------------- Location and map state ----------------
  LatLng _currentLocation = const LatLng(37.7749, -122.4194);
  double _gpsAccuracy = 0.0;
  bool _isLocationServiceActive = true;
  bool _isSmsActive = false;
  bool _isRecordingEvidence = false;
  Set<Circle> _circles = {};

  // ---------------- Timer state ----------------
  Duration _elapsedTime = Duration.zero;

  // ✅ Avoid duplicate SMS sending
  bool _smsAlreadySent = false;

  @override
  void initState() {
    super.initState();

    // ✅ Prepare UI cards for static numbers
    _staticContactsUI = _staticEmergencyNumbers
        .map(
          (phone) => {
            "name": "Emergency Contact",
            "phone": phone,
            "relation": "Static",
            "status": "pending",
            "timestamp": DateTime.now(),
          },
        )
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _initializeAll();
        debugPrint("✅ SOS fully started");
      } catch (e) {
        debugPrint("❌ SOS init failed: $e");
      }
    });
  }

  // ✅ Get username safely
  String _getUserNameForSms() {
    final user = _auth.currentUser;
    if (user == null) return "SilentShield User";

    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email;

    return "SilentShield User";
  }

  // ---------------- MAIN INIT ----------------
  Future<void> _initializeAll() async {
    // ✅ 1) Create SOS doc (ONLY STORES lat,lng,mapLink)
    await _saveSosStartToFirestore();

    // ✅ 2) Send SMS to STATIC numbers using Twilio backend
    await _sendSosSmsToStaticNumbers();

    // ✅ 3) Save notification status in Firestore
    await _saveStaticNotificationLogs();

    // ✅ 4) Start SOS services + auto audio record
    await _initializeEmergencyMode();
  }

  // ✅ SOS START Save (ONLY 3 fields)
  Future<void> _saveSosStartToFirestore() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = pos.latitude;
      final lng = pos.longitude;
      final mapLink = "https://www.google.com/maps?q=$lat,$lng";

      final docRef = await _sosRef.add({
        "status": "SENT",
        "triggerType": "button",
        "createdAt": FieldValue.serverTimestamp(),

        // ✅ Minimal fields only
        "lat": lat,
        "lng": lng,
        "mapLink": mapLink,
      });

      _sosDocId = docRef.id;

      debugPrint("✅ SOS START saved minimal data: $_sosDocId");
    } catch (e) {
      debugPrint("❌ SOS START failed: $e");
    }
  }

  // ✅ SEND SOS SMS TO STATIC NUMBERS (WITH USERNAME + MAP LINK)
  Future<void> _sendSosSmsToStaticNumbers() async {
    try {
      if (_smsAlreadySent) return;

      final numbers = _staticEmergencyNumbers;

      if (numbers.isEmpty) {
        debugPrint("❌ Static emergency numbers list empty");
        setState(() => _isSmsActive = false);
        return;
      }

      // ✅ Get location
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = pos.latitude;
      final lng = pos.longitude;
      final mapLink = "https://www.google.com/maps?q=$lat,$lng";

      // ✅ Username
      final userName = _getUserNameForSms();

      final message =
          "🚨 SOS ALERT from SilentShield!\n"
          "👤 User: $userName\n"
          "Help me immediately!\n\n"
          "📍 Location: $mapLink\n";

      // ✅ Twilio API call
      await SosSmsService.sendSOS(message: message, numbers: numbers);

      _smsAlreadySent = true;

      setState(() => _isSmsActive = true);

      // ✅ Update UI status
      setState(() {
        for (var c in _staticContactsUI) {
          c["status"] = "delivered";
          c["timestamp"] = DateTime.now();
        }
      });

      debugPrint("✅ SOS SMS sent to static numbers: $numbers");
    } catch (e) {
      setState(() => _isSmsActive = false);

      // ✅ Update UI status
      setState(() {
        for (var c in _staticContactsUI) {
          c["status"] = "failed";
          c["timestamp"] = DateTime.now();
        }
      });

      debugPrint("❌ SMS sending failed: $e");
    }
  }

  // ✅ Save notifications inside Firestore (static contacts)
  Future<void> _saveStaticNotificationLogs() async {
    try {
      if (_sosDocId == null) return;

      for (int i = 0; i < _staticContactsUI.length; i++) {
        final c = _staticContactsUI[i];

        await _sosRef.doc(_sosDocId).collection("notifications").add({
          "name": c["name"],
          "phone": c["phone"],
          "relation": c["relation"],
          "status": _isSmsActive ? "SENT" : "FAILED",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      debugPrint("✅ Notification logs saved");
    } catch (e) {
      debugPrint("❌ Notification log save failed: $e");
    }
  }

  // ---------------- SOS SERVICES ----------------
  Future<void> _initializeEmergencyMode() async {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WakelockPlus.enable();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _radiusController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _startLocationUpdates();
    _startElapsedTimeCounter();
    _startHapticFeedback();

    // ✅ AUTO START MIC RECORDING HERE
    await _startEvidenceRecording();
  }

  // ✅ AUTO RECORD starts when SOS screen starts
  Future<void> _startEvidenceRecording() async {
    try {
      final permission = await _evidenceRecorder.hasPermission();
      if (!permission) {
        debugPrint("❌ Mic permission denied");
        return;
      }

      final fileName = "evidence_${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _evidenceRecorder.start(const RecordConfig(), path: fileName);

      setState(() => _isRecordingEvidence = true);

      debugPrint("✅ Evidence recording started: $fileName");
    } catch (e) {
      debugPrint("❌ Evidence record error: $e");
      setState(() => _isRecordingEvidence = false);
    }
  }

  // ✅ Stop + Upload evidence audio when SOS ends
  Future<void> _stopAndUploadEvidenceAudio() async {
    try {
      if (_sosDocId == null) return;

      final localPath = await _evidenceRecorder.stop();
      setState(() => _isRecordingEvidence = false);

      if (localPath == null) {
        debugPrint("❌ Recording stopped but file path is NULL");
        return;
      }

      final file = File(localPath);
      if (!file.existsSync()) {
        debugPrint("❌ File not found: $localPath");
        return;
      }

      final storageName =
          "evidence_${DateTime.now().millisecondsSinceEpoch}.m4a";

      final ref = _storage.ref().child(
        "sos_audio/$_uid/$_sosDocId/$storageName",
      );

      final task = await ref.putFile(file);
      final audioUrl = await task.ref.getDownloadURL();

      await _sosRef.doc(_sosDocId).update({
        "audioUrl": audioUrl,
        "audioDurationSec": _elapsedTime.inSeconds,
        "audioStatus": "UPLOADED",
        "audioUploadedAt": FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Audio uploaded & saved into SOS doc");
    } catch (e) {
      debugPrint("❌ Stop/Upload evidence failed: $e");
    }
  }

  void _startLocationUpdates() {
    _updateLocation();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateLocation();
    });
  }

  // ✅ Live tracking update (ONLY lat,lng,mapLink)
  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _gpsAccuracy = position.accuracy;
        _isLocationServiceActive = true;

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

      // ✅ SAVE MINIMAL LIVE LOCATION INSIDE SOS DOC
      if (_sosDocId != null) {
        final lat = position.latitude;
        final lng = position.longitude;
        final mapLink = "https://www.google.com/maps?q=$lat,$lng";

        await _sosRef.doc(_sosDocId).update({
          "lat": lat,
          "lng": lng,
          "mapLink": mapLink,
        });
      }
    } catch (_) {
      setState(() => _isLocationServiceActive = false);
    }
  }

  void _startElapsedTimeCounter() {
    _elapsedTimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
      });
    });
  }

  void _startHapticFeedback() {
    _hapticTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 200);
      }
    });
  }

  String _formatElapsedTime() {
    final h = _elapsedTime.inHours.toString().padLeft(2, '0');
    final m = (_elapsedTime.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsedTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showCancelEmergencyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CancelEmergencyDialog(onPinVerified: _cancelEmergency),
    );
  }

  // ✅ SOS cancel → STOP RECORD → UPLOAD → UPDATE SOS END
  Future<void> _cancelEmergency() async {
    await _stopAndUploadEvidenceAudio();

    if (_sosDocId != null) {
      await _sosRef.doc(_sosDocId).update({
        "endStatus": "DEACTIVATED",
        "endedAt": FieldValue.serverTimestamp(),
      });
    }

    _locationUpdateTimer?.cancel();
    _elapsedTimeTimer?.cancel();
    _hapticTimer?.cancel();

    WakelockPlus.disable();

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

  @override
  void dispose() {
    _pulseController.dispose();
    _radiusController.dispose();

    _locationUpdateTimer?.cancel();
    _elapsedTimeTimer?.cancel();
    _hapticTimer?.cancel();

    _evidenceRecorder.dispose();
    _mapController?.dispose();

    WakelockPlus.disable();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async => false,
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
                onMapCreated: (controller) => _mapController = controller,
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
            child: _staticContactsUI.isEmpty
                ? Center(
                    child: Text(
                      "No contacts",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _staticContactsUI.length,
                    separatorBuilder: (_, __) => SizedBox(width: 3.w),
                    itemBuilder: (context, index) {
                      return EmergencyContactStatusCard(
                        contact: _staticContactsUI[index],
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
            child: GestureDetector(
              onLongPress: _showCancelEmergencyDialog,
              child: Container(
                height: 7.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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

// ---------------- CANCEL DIALOG ----------------
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

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          Navigator.pop(context);
        }
      });
    });
  }

  void _verifyPin() {
    setState(() => _isVerifying = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_pinController.text == '1234') {
        _timeoutTimer?.cancel();
        Navigator.pop(context);
        widget.onPinVerified();
      } else {
        setState(() {
          _isVerifying = false;
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
    return AlertDialog(
      title: Text("Enter Emergency PIN ($_remainingSeconds s)"),
      content: Pinput(
        controller: _pinController,
        length: 4,
        obscureText: true,
        onCompleted: (_) => _verifyPin(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verifyPin,
          child: const Text("Verify"),
        ),
      ],
    );
  }
}
