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

  CollectionReference get _contactsRef =>
      _firestore.collection("Users").doc(_uid).collection("contacts");

  CollectionReference get _sosRef =>
      _firestore.collection("Users").doc(_uid).collection("sos_logs");

  String? _sosDocId;
  bool _sosStartSaved = false;

  // ---------------- Controllers and state ----------------
  GoogleMapController? _mapController;
  late AnimationController _pulseController;
  late AnimationController _radiusController;

  Timer? _locationUpdateTimer;
  Timer? _elapsedTimeTimer;
  Timer? _hapticTimer;

  // ✅ IMPORTANT: 2 recorders (One for evidence, one for voice note)
  final AudioRecorder _evidenceRecorder = AudioRecorder();
  final AudioRecorder _voiceRecorder = AudioRecorder();

  // ---------------- Location and map state ----------------
  LatLng _currentLocation = const LatLng(37.7749, -122.4194);
  double _gpsAccuracy = 0.0;
  bool _isLocationServiceActive = true;
  bool _isSmsActive = false;
  bool _isRecordingEvidence = false;
  Set<Circle> _circles = {};

  // ---------------- Timer state ----------------
  Duration _elapsedTime = Duration.zero;

  // ✅ Contacts from Firestore (current user only)
  List<Map<String, dynamic>> _emergencyContacts = [];

  // ✅ Voice note state
  bool _isVoiceRecording = false;
  Duration _voiceDuration = Duration.zero;
  Timer? _voiceTimer;

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }

  // ---------------- MAIN INIT ----------------
  Future<void> _initializeAll() async {
    // ✅ 1) Save SOS START
    await _saveSosStartToFirestore();

    // ✅ 2) Load user's contacts
    await _loadEmergencyContactsFromFirestore();

    // ✅ 3) Notify contacts (log status in Firestore)
    await _notifyContactsAndSaveStatus();

    // ✅ 4) Start SOS services
    await _initializeEmergencyMode();
  }

  // ✅ SOS START Save (your required format)
  Future<void> _saveSosStartToFirestore() async {
    try {
      if (_sosStartSaved) return;

      final docRef = await _sosRef.add({
        "status": "SENT",
        "triggerType": "button",
        "createdAt": FieldValue.serverTimestamp(),
      });

      _sosDocId = docRef.id;
      _sosStartSaved = true;

      debugPrint("✅ SOS START saved: $_sosDocId");
    } catch (e) {
      debugPrint("❌ SOS START failed: $e");
    }
  }

  // ✅ SOS END update
  Future<void> _saveSosEndToFirestore() async {
    try {
      if (_sosDocId == null) return;

      await _sosRef.doc(_sosDocId).update({
        "endStatus": "DEACTIVATED",
        "endedAt": FieldValue.serverTimestamp(),
      });

      debugPrint("✅ SOS END updated: $_sosDocId");
    } catch (e) {
      debugPrint("❌ SOS END update failed: $e");
    }
  }

  // ✅ Load contacts from Firestore (current user only)
  Future<void> _loadEmergencyContactsFromFirestore() async {
    try {
      final snapshot = await _contactsRef
          .orderBy("createdAt", descending: true)
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "docId": doc.id,
          "name": data["name"] ?? "",
          "phone": data["phone"] ?? "",
          "relation": data["relation"] ?? "",
          "status": "pending",
          "timestamp": DateTime.now(),
        };
      }).toList();

      setState(() => _emergencyContacts = list);

      debugPrint("✅ Contacts loaded: ${_emergencyContacts.length}");
    } catch (e) {
      debugPrint("❌ Failed to load contacts: $e");
    }
  }

  // ✅ Notify contacts and store status log in Firestore
  Future<void> _notifyContactsAndSaveStatus() async {
    try {
      if (_sosDocId == null) return;

      if (_emergencyContacts.isEmpty) {
        debugPrint("⚠️ No contacts to notify.");
        return;
      }

      for (int i = 0; i < _emergencyContacts.length; i++) {
        final c = _emergencyContacts[i];

        await _sosRef.doc(_sosDocId).collection("notifications").add({
          "name": c["name"],
          "phone": c["phone"],
          "relation": c["relation"],
          "status": "SENT",
          "createdAt": FieldValue.serverTimestamp(),
        });

        setState(() {
          _emergencyContacts[i]["status"] = "delivered";
          _emergencyContacts[i]["timestamp"] = DateTime.now();
        });
      }

      debugPrint("✅ Notification logs stored.");
    } catch (e) {
      debugPrint("❌ Failed to notify contacts: $e");
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

    // ✅ Evidence recording runs in background
    await _startEvidenceRecording();

    _checkNetworkStatus();
  }

  void _startLocationUpdates() {
    _updateLocation();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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
    } catch (_) {
      setState(() {
        _isLocationServiceActive = false;
      });
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

  Future<void> _startEvidenceRecording() async {
    try {
      if (await _evidenceRecorder.hasPermission()) {
        await _evidenceRecorder.start(
          const RecordConfig(),
          path: "emergency_evidence.m4a",
        );
        setState(() => _isRecordingEvidence = true);
      }
    } catch (e) {
      debugPrint("❌ Evidence record error: $e");
      setState(() => _isRecordingEvidence = false);
    }
  }

  void _checkNetworkStatus() {
    setState(() => _isSmsActive = false);
  }

  // ---------------- VOICE NOTE RECORD ----------------

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _toggleVoiceRecording() async {
    try {
      // ✅ STOP
      if (_isVoiceRecording) {
        final path = await _voiceRecorder.stop();
        _voiceTimer?.cancel();

        setState(() => _isVoiceRecording = false);

        if (path != null) {
          await _uploadVoiceNoteToFirebase(path);
        }
        return;
      }

      // ✅ START
      final permission = await _voiceRecorder.hasPermission();
      if (!permission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone permission denied")),
          );
        }
        return;
      }

      final fileName = "voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _voiceRecorder.start(const RecordConfig(), path: fileName);

      setState(() {
        _isVoiceRecording = true;
        _voiceDuration = Duration.zero;
      });

      _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _voiceDuration = Duration(seconds: _voiceDuration.inSeconds + 1);
        });
      });
    } catch (e) {
      debugPrint("❌ Voice record error: $e");
    }
  }

  Future<void> _uploadVoiceNoteToFirebase(String localPath) async {
    try {
      if (_sosDocId == null) return;

      final fileName = "voice_${DateTime.now().millisecondsSinceEpoch}.m4a";
      final ref = _storage.ref().child("sos_audio/$_uid/$_sosDocId/$fileName");

      final file = File(localPath);
      final task = await ref.putFile(file);
      final audioUrl = await task.ref.getDownloadURL();

      // ✅ Save audio URL in Firestore
      await _sosRef.doc(_sosDocId).collection("voice_notes").add({
        "audioUrl": audioUrl,
        "durationSec": _voiceDuration.inSeconds,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Voice note uploaded & saved")),
        );
      }

      debugPrint("✅ Voice note saved: $audioUrl");
    } catch (e) {
      debugPrint("❌ Upload error: $e");
    }
  }

  // ---------------- CANCEL SOS ----------------
  void _showCancelEmergencyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CancelEmergencyDialog(onPinVerified: _cancelEmergency),
    );
  }

  Future<void> _cancelEmergency() async {
    // ✅ stop voice if recording
    if (_isVoiceRecording) {
      await _voiceRecorder.stop();
      _voiceTimer?.cancel();
      setState(() => _isVoiceRecording = false);
    }

    // ✅ Save SOS END
    await _saveSosEndToFirestore();

    _locationUpdateTimer?.cancel();
    _elapsedTimeTimer?.cancel();
    _hapticTimer?.cancel();

    try {
      await _evidenceRecorder.stop();
    } catch (_) {}

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

  // ---------------- DISPOSE ----------------
  @override
  void dispose() {
    _pulseController.dispose();
    _radiusController.dispose();

    _locationUpdateTimer?.cancel();
    _elapsedTimeTimer?.cancel();
    _hapticTimer?.cancel();

    _voiceTimer?.cancel();

    _evidenceRecorder.dispose();
    _voiceRecorder.dispose();

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

  String _formatElapsedTime() {
    final h = _elapsedTime.inHours.toString().padLeft(2, '0');
    final m = (_elapsedTime.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsedTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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
            child: _emergencyContacts.isEmpty
                ? Center(
                    child: Text(
                      "No contacts added",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emergencyContacts.length,
                    separatorBuilder: (_, __) => SizedBox(width: 3.w),
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
          SizedBox(width: 3.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _toggleVoiceRecording, // ✅ voice note record upload
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
                    iconName: _isVoiceRecording ? 'stop' : 'mic',
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _isVoiceRecording ? "RECORDING..." : "VOICE NOTE",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isVoiceRecording) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      _formatDuration(_voiceDuration),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
