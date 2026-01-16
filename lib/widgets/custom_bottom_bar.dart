import 'package:flutter/material.dart';

/// Custom bottom navigation bar for SilentShield application.
/// Implements thumb-optimized emergency access with fixed navigation pattern.
///
/// This widget is parameterized and reusable across different implementations.
/// Navigation logic is NOT hardcoded - it accepts currentIndex and onTap callback.
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: theme.textTheme.bodySmall?.color,
      selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
      unselectedLabelStyle: theme.bottomNavigationBarTheme.unselectedLabelStyle,
      elevation: 8.0,
      items: [
        // Home/Shield - Dashboard with central SOS
        BottomNavigationBarItem(
          icon: Icon(Icons.shield_outlined, size: 24),
          activeIcon: Icon(Icons.shield, size: 24),
          label: 'Shield',
          tooltip: 'Safety Dashboard',
        ),

        // Contacts/People - Trusted contacts management
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline, size: 24),
          activeIcon: Icon(Icons.people, size: 24),
          label: 'Contacts',
          tooltip: 'Trusted Contacts',
        ),

        // Activity/Clock - Logs and history
        BottomNavigationBarItem(
          icon: Icon(Icons.history, size: 24),
          activeIcon: Icon(Icons.history, size: 24),
          label: 'Activity',
          tooltip: 'Activity Logs',
        ),

        // Profile/User - Account and preferences
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline, size: 24),
          activeIcon: Icon(Icons.person, size: 24),
          label: 'Profile',
          tooltip: 'Profile',
        ),
      ],
    );
  }
}
