import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendSos() async {
    debugPrint('🟡 SOS: sendSos() CALLED');

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('🔴 SOS ERROR: user is NULL');
      throw Exception('No user logged in');
    }

    debugPrint('🟢 SOS USER UID: ${user.uid}');
    debugPrint('🟢 SOS USER EMAIL: ${user.email}');

    try {
      await _firestore.collection('sos_events').add({
        'uid': user.uid,
        'email': user.email,
        'status': 'SENT',
        'triggerType': 'button',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ SOS WRITE SUCCESS');
    } catch (e) {
      debugPrint('❌ SOS WRITE FAILED: $e');
      rethrow;
    }
  }
}
