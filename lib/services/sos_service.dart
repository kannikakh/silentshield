import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendSos() async {
    debugPrint('🟡 SOS: sendSos() CALLED');

    final user = _auth.currentUser;

    if (user == null) {
      debugPrint('🔴 SOS ERROR: user is NULL');
      throw Exception('No user logged in');
    }

    debugPrint('🟢 SOS USER UID: ${user.uid}');
    debugPrint('🟢 SOS USER EMAIL: ${user.email}');

    try {
      await _firestore.collection('sos_events').add({
        // 🔑 MOST IMPORTANT (for filtering)
        'uid': user.uid,

        // optional but useful
        'email': user.email,

        // status info
        'status': 'SENT',
        'triggerType': 'button',

        // 🔥 Firestore timestamp
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ SOS WRITE SUCCESS');
    } catch (e, s) {
      debugPrint('❌ SOS WRITE FAILED: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }
}



