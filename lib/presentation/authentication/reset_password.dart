import 'package:flutter/material.dart';
import '../../services/local_user_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSetNewPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final exists = await LocalUserService.hasUser(widget.email);
    if (!exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No local account found')));
      setState(() => _isLoading = false);
      return;
    }
    final users = await LocalUserService.loadUsers();
    users[widget.email] = _passwordCtrl.text;
    await LocalUserService.saveUsers(users);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated (local). You may now sign in.'),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set New Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Resetting password for ${widget.email}'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? '6+ chars required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtrl,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                obscureText: true,
                validator: (v) =>
                    v != _passwordCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSetNewPassword,
                child: const Text('Set Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
