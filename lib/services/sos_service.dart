import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SosService {
  DateTime? _lastSOS;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendSos() async {
    // Prevent spam SOS
    if (_lastSOS != null) {
      final difference = DateTime.now().difference(_lastSOS!);

      if (difference.inSeconds < 30) {
        debugPrint('⚠️ SOS BLOCKED (cooldown)');

        return;
      }
    }

    _lastSOS = DateTime.now();

    debugPrint('🟡 SOS: sendSos() CALLED');

    final user = _auth.currentUser;

    if (user == null) {
      debugPrint('🔴 SOS ERROR: user is NULL');

      return;
    }

    try {
      await _firestore
    .collection('sos_events')
    .add({
      'uid': user.uid,
      'email': user.email,
      'status': 'SENT',
      'triggerType': 'button',
      'createdAt': FieldValue.serverTimestamp(),
    })
    .timeout(const Duration(seconds: 5));
      debugPrint('✅ SOS WRITE SUCCESS');
    } catch (e, s) {

  debugPrint('❌ SOS WRITE FAILED: $e');

  debugPrintStack(stackTrace: s);

  return;
}
  }
}
