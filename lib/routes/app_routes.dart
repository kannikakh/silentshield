import 'package:flutter/material.dart';
import '../presentation/authentication/authentication.dart';
import '../presentation/permissions_setup/permissions_setup.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/voice_shield_call_overlay/voice_shield_call_overlay.dart';
import '../presentation/sos_activated/sos_activated.dart';
import '../presentation/contacts/contacts.dart';
import '../presentation/activity/activity.dart';
import '../presentation/settings/settings.dart';
import '../presentation/authentication/reset_password.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String authentication = '/authentication';
  static const String permissionsSetup = '/permissions-setup';
  static const String homeDashboard = '/home-dashboard';
  static const String onboardingFlow = '/onboarding-flow';
  static const String voiceShieldCallOverlay = '/voice-shield-call-overlay';
  static const String sosActivated = '/sos-activated';
  static const String contacts = '/contacts';
  static const String activity = '/activity';
  static const String settings = '/settings';
  static const String resetPassword = '/reset-password';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const OnboardingFlow(),
    authentication: (context) => const Authentication(),
    permissionsSetup: (context) => const PermissionsSetup(),
    homeDashboard: (context) => const HomeDashboard(),
    onboardingFlow: (context) => const OnboardingFlow(),
    voiceShieldCallOverlay: (context) => const VoiceShieldCallOverlay(),
    sosActivated: (context) => const SosActivated(),
    contacts: (context) => const ContactsScreen(),
    activity: (context) => const ActivityScreen(),
    settings: (context) => const ProfileScreen(),
    resetPassword: (context) => const ResetPasswordScreen(email: ''),
    // TODO: Add your other routes here
  };
}
