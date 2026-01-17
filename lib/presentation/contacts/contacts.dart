import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/contact_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactService _service = ContactService();

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
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (docId == null) {
        // ADD
        await _service.firestore.collection('Contacts').add({
          'name': nameCtrl.text.trim(),
          'Phone': phoneCtrl.text.trim(),
          'Relation': relationCtrl.text.trim(),
          'priority': 1,
          'uid': _service.userPath,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // UPDATE
        await _service.firestore.collection('Contacts').doc(docId).update({
          'name': nameCtrl.text.trim(),
          'Phone': phoneCtrl.text.trim(),
          'Relation': relationCtrl.text.trim(),
        });
      }
    }
  }

  Future<void> _deleteContact(String docId) async {
    await _service.firestore.collection('Contacts').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
   debugPrint('CONTACT SCREEN BUILD CALLED');


    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.firestore
    .collection('Contacts')
    .snapshots(),

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
                subtitle: Text('${data['Relation']} • ${data['Phone']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await _showAddDialog(
                        docId: doc.id,
                        name: data['name'],
                        phone: data['Phone'],
                        relation: data['Relation'],
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
