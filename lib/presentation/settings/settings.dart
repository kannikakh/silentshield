import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _email;
  bool _motion = true;
  bool _audio = true;
  bool _voiceShield = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('current_user');
    setState(() {
      _email = user;
      _motion = prefs.getBool('motion') ?? true;
      _audio = prefs.getBool('audio') ?? true;
      _voiceShield = prefs.getBool('voiceShield') ?? true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('motion', _motion);
    await prefs.setBool('audio', _audio);
    await prefs.setBool('voiceShield', _voiceShield);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved (local).')));
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    try {
      if (SupabaseService.supabaseUrl.isNotEmpty &&
          SupabaseService.supabaseAnonKey.isNotEmpty) {
        await SupabaseService.instance.client.auth.signOut();
      }
    } catch (_) {}
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out')));
    Navigator.of(context).pushReplacementNamed(AppRoutes.authentication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ListTile(
              title: const Text('Email'),
              subtitle: Text(_email ?? 'Not signed in'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Monitoring',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SwitchListTile(
              title: const Text('Motion AI'),
              value: _motion,
              onChanged: (v) => setState(() => _motion = v),
            ),
            SwitchListTile(
              title: const Text('Audio AI'),
              value: _audio,
              onChanged: (v) => setState(() => _audio = v),
            ),
            SwitchListTile(
              title: const Text('VoiceShield'),
              value: _voiceShield,
              onChanged: (v) => setState(() => _voiceShield = v),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed('/reset-password'),
            ),
            ListTile(
              title: const Text('Logout'),
              trailing: const Icon(Icons.logout),
              onTap: _logout,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
