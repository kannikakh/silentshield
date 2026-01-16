import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/custom_bottom_bar.dart';
import './home_dashboard_initial_page.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  HomeDashboardState createState() => HomeDashboardState();
}

class HomeDashboardState extends State<HomeDashboard> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;

  final List<String> routes = [
    AppRoutes.homeDashboard,
    AppRoutes.contacts,
    AppRoutes.activity,
    AppRoutes.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: '/home-dashboard',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/home-dashboard' || '/':
              return MaterialPageRoute(
                builder: (context) => const HomeDashboardInitialPage(),
                settings: settings,
              );
            default:
              if (AppRoutes.routes.containsKey(settings.name)) {
                return MaterialPageRoute(
                  builder: AppRoutes.routes[settings.name]!,
                  settings: settings,
                );
              }
              return null;
          }
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (!AppRoutes.routes.containsKey(routes[index])) {
            return;
          }
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
      ),
    );
  }
}
