import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('contacts');
    if (raw != null) {
      final List<dynamic> list = jsonDecode(raw);
      setState(
        () => _contacts = list.map((e) => Map<String, String>.from(e)).toList(),
      );
    } else {
      // seed with demo contacts on first run
      _contacts = [
        {'name': 'Alice Johnson', 'phone': '+1 555 0100', 'relation': 'Friend'},
        {'name': 'Bob Singh', 'phone': '+1 555 0111', 'relation': 'Family'},
      ];
      await prefs.setString('contacts', jsonEncode(_contacts));
      setState(() {});
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('contacts', jsonEncode(_contacts));
  }

  Future<void> _showAddDialog({int? editIndex}) async {
    final nameCtrl = TextEditingController(
      text: editIndex != null ? _contacts[editIndex]['name'] : '',
    );
    final phoneCtrl = TextEditingController(
      text: editIndex != null ? _contacts[editIndex]['phone'] : '',
    );
    final relationCtrl = TextEditingController(
      text: editIndex != null ? _contacts[editIndex]['relation'] : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editIndex == null ? 'Add Contact' : 'Edit Contact'),
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
      final entry = {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'relation': relationCtrl.text.trim(),
      };
      setState(() {
        if (editIndex != null)
          _contacts[editIndex] = entry;
        else
          _contacts.insert(0, entry);
      });
      await _saveContacts();
    }
  }

  Future<void> _deleteContact(int index) async {
    setState(() => _contacts.removeAt(index));
    await _saveContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ElevatedButton.icon(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
            );
          }

          final c = _contacts[index - 1];
          return ListTile(
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(c['name'] ?? ''),
            subtitle: Text('${c['relation'] ?? ''} • ${c['phone'] ?? ''}'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit') {
                  await _showAddDialog(editIndex: index - 1);
                } else if (v == 'delete') {
                  await _deleteContact(index - 1);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          );
        },
      ),
    );
  }
}
