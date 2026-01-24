import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _contactRef =>
      _firestore.collection('Users').doc(_uid).collection('contacts');

  Future<void> _showAddDialog({
    String? docId,
    String? name,
    String? phone,
    String? relation,
  }) async {
    final nameCtrl = TextEditingController(text: name ?? '');
    final phoneCtrl = TextEditingController(text: phone ?? '');
    final relationCtrl = TextEditingController(text: relation ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(docId == null ? 'Add Contact' : 'Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: relationCtrl,
              decoration: const InputDecoration(labelText: 'Relation'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final data = {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'relation': relationCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (docId == null) {
        // ✅ ADD (USER SPECIFIC)
        await _contactRef.add(data);
      } else {
        // ✅ UPDATE
        await _contactRef.doc(docId).update(data);
      }
    }
  }

  Future<void> _deleteContact(String docId) async {
    await _contactRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _contactRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ElevatedButton.icon(
                  onPressed: () => _showAddDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Contact'),
                );
              }

              final doc = docs[index - 1];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(data['name'] ?? ''),
                subtitle:
                    Text('${data['relation'] ?? ''} • ${data['phone'] ?? ''}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await _showAddDialog(
                        docId: doc.id,
                        name: data['name'],
                        phone: data['phone'],
                        relation: data['relation'],
                      );
                    } else if (v == 'delete') {
                      await _deleteContact(doc.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
