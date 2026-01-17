import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String get userPath {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return '/Users/${user.uid}';
  }
}
