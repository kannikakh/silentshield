import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/email_input_widget.dart';
import './widgets/emergency_pin_setup_widget.dart';
import './widgets/password_input_widget.dart';
import 'registration.dart';
import 'forgot_password.dart';

class Authentication extends StatefulWidget {
  const Authentication({super.key});

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoading = false;
  bool _showPinSetup = false;
  bool _biometricAvailable = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔹 Check biometric support
  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      setState(() => _biometricAvailable = canCheck && supported);
    } catch (_) {
      setState(() => _biometricAvailable = false);
    }
  }

  // 🔹 Biometric authentication (THIS WAS MISSING BEFORE)
  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access SilentShield',
      );

      if (authenticated) {
        HapticFeedback.mediumImpact();
        _navigateToHome();
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Biometric authentication failed';
      });
    }
  }

  // 🔹 Firebase email/password sign in
  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      // 🔥 Save user in Firestore Users collection
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        }, SetOptions(merge: true));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', email);

      HapticFeedback.mediumImpact();
      setState(() {
        _isLoading = false;
        _showPinSetup = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Sign in failed';
      });
    }
  }

  void _handlePinSetupComplete() {
    HapticFeedback.mediumImpact();
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context, rootNavigator: true)
        .pushReplacementNamed('/home-dashboard');
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _navigateToRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _showPinSetup
            ? EmergencyPinSetupWidget(onComplete: _handlePinSetupComplete)
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 8.h),
                      _buildLogo(theme),
                      SizedBox(height: 6.h),
                      _buildWelcomeText(),
                      SizedBox(height: 4.h),
                      if (_errorMessage != null) _buildErrorMessage(theme),
                      EmailInputWidget(controller: _emailController),
                      SizedBox(height: 2.h),
                      PasswordInputWidget(controller: _passwordController),
                      SizedBox(height: 1.h),
                      _buildForgotPasswordLink(),
                      SizedBox(height: 4.h),
                      _buildSignInButton(),
                      if (_biometricAvailable) ...[
                        SizedBox(height: 3.h),
                        _buildBiometricButton(),
                      ],
                      SizedBox(height: 4.h),
                      _buildCreateAccountLink(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: CustomIconWidget(
            iconName: 'shield',
            color: theme.colorScheme.onPrimary,
            size: 10.w,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'SilentShield',
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: const [
        Text(
          'Welcome Back',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          'Sign in to access your safety dashboard',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        _errorMessage!,
        style: TextStyle(color: theme.colorScheme.error),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _navigateToForgotPassword,
        child: const Text('Forgot Password?'),
      ),
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSignIn,
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('Sign In'),
    );
  }

  Widget _buildBiometricButton() {
    return OutlinedButton.icon(
      onPressed: () => _authenticateWithBiometric(),
      icon: const Icon(Icons.fingerprint),
      label: const Text('Sign in with Biometric'),
    );
  }

  Widget _buildCreateAccountLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('New User? '),
        TextButton(
          onPressed: _navigateToRegistration,
          child: const Text('Create Account'),
        ),
      ],
    );
  }
}
