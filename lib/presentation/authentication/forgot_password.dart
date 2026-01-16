import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/local_user_service.dart';
import 'reset_password.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final email = _emailCtrl.text.trim();

    try {
      if (SupabaseService.supabaseUrl.isNotEmpty &&
          SupabaseService.supabaseAnonKey.isNotEmpty) {
        await SupabaseService.instance.client.auth.resetPasswordForEmail(email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      // Fallback: if local user exists, open immediate reset screen
      final exists = await LocalUserService.hasUser(email);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No Supabase configured — opening local reset.'),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email)),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No account found for that email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reset failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter email' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleReset,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Send Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
