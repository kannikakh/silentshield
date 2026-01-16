import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/email_input_widget.dart';
import './widgets/emergency_pin_setup_widget.dart';
import './widgets/password_input_widget.dart';
import 'registration.dart';
import 'forgot_password.dart';
import '../../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_user_service.dart';

/// Authentication screen for SilentShield application.
/// Provides secure login with emergency PIN setup for crisis situations.
/// Implements biometric authentication support for enhanced security.
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

  /// Check if biometric authentication is available on device
  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _biometricAvailable = canCheckBiometrics && isDeviceSupported;
      });
    } catch (e) {
      setState(() => _biometricAvailable = false);
    }
  }

  /// Authenticate user with biometric
  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access SilentShield',
      );

      if (authenticated) {
        HapticFeedback.mediumImpact();
        _navigateToHome();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Biometric authentication failed');
    }
  }

  /// Handle sign in with email and password
  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate authentication delay
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // If Supabase configured, use it
      if (SupabaseService.supabaseUrl.isNotEmpty &&
          SupabaseService.supabaseAnonKey.isNotEmpty) {
        final res = await SupabaseService.instance.client.auth
            .signInWithPassword(email: email, password: password);
        // If sign in succeeded, navigate to pin setup
        if (res.session != null || res.user != null) {
          // persist current session locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user', email);
          HapticFeedback.mediumImpact();
          setState(() {
            _isLoading = false;
            _showPinSetup = true;
          });
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign in failed. Please check your credentials.';
        });
        return;
      }

      // Fallback: check local user service
      final ok = await LocalUserService.validate(email, password);
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', email);
        HapticFeedback.mediumImpact();
        setState(() {
          _isLoading = false;
          _showPinSetup = true;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid email or password. Please try again.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sign in error: $e';
      });
    }
  }

  /// Handle PIN setup completion
  void _handlePinSetupComplete() {
    HapticFeedback.mediumImpact();
    _navigateToHome();
  }

  /// Navigate to home dashboard
  void _navigateToHome() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed('/home-dashboard');
  }

  /// Navigate to forgot password
  void _navigateToForgotPassword() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
  }

  /// Navigate to registration
  void _navigateToRegistration() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrationScreen()));
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
                      _buildWelcomeText(theme),
                      SizedBox(height: 4.h),
                      if (_errorMessage != null) _buildErrorMessage(theme),
                      EmailInputWidget(controller: _emailController),
                      SizedBox(height: 2.h),
                      PasswordInputWidget(controller: _passwordController),
                      SizedBox(height: 1.h),
                      _buildForgotPasswordLink(theme),
                      SizedBox(height: 4.h),
                      _buildSignInButton(theme),
                      if (_biometricAvailable) ...[
                        SizedBox(height: 3.h),
                        _buildBiometricButton(theme),
                      ],
                      SizedBox(height: 4.h),
                      _buildCreateAccountLink(theme),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// Build SilentShield logo
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
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Build welcome text
  Widget _buildWelcomeText(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'Sign in to access your safety dashboard',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build error message
  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            color: theme.colorScheme.error,
            size: 5.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build forgot password link
  Widget _buildForgotPasswordLink(ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _navigateToForgotPassword,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Forgot Password?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Build sign in button
  Widget _buildSignInButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSignIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: _isLoading
          ? SizedBox(
              height: 2.5.h,
              width: 2.5.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            )
          : Text(
              'Sign In',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  /// Build biometric authentication button
  Widget _buildBiometricButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _authenticateWithBiometric,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        side: BorderSide(color: theme.colorScheme.outline, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: CustomIconWidget(
        iconName: 'fingerprint',
        color: theme.colorScheme.primary,
        size: 6.w,
      ),
      label: Text(
        'Sign in with Biometric',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Build create account link
  Widget _buildCreateAccountLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New User? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: _navigateToRegistration,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Create Account',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
