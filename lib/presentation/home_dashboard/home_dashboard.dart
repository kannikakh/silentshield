import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 🔴 Speech + Local storage
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // 🔴 Speech & Code word
  final SpeechToText _speech = SpeechToText();
  String _codeWord = '';
  int _speakCount = 0;
  bool _isListening = false;

  final List<String> routes = [
    AppRoutes.homeDashboard,
    AppRoutes.contacts,
    AppRoutes.activity,
    AppRoutes.settings,
  ];

  @override
  void initState() {
    super.initState();
    _loadCodeWord();
    _initSpeech();
  }

  // 🔹 Load code word saved at login
  Future<void> _loadCodeWord() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _codeWord = (prefs.getString('code_word') ?? '').toLowerCase();
    });
  }

  // 🔹 Init speech engine
  Future<void> _initSpeech() async {
    await _speech.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
      onStatus: (s) => debugPrint('Speech status: $s'),
    );

    // 🔴 Start listening automatically after init
    _startListening();
  }

  // 🔥 STEP 6: START LISTENING + COUNT
  void _startListening() async {
    if (_isListening) return;
    if (_codeWord.isEmpty) return;

    _isListening = true;

    await _speech.listen(
      listenMode: ListenMode.dictation,
      partialResults: true,
      onResult: (result) {
        final spoken = result.recognizedWords.toLowerCase();

        if (spoken.contains(_codeWord)) {
          _speakCount++;
          debugPrint('Code word spoken $_speakCount times');

          // Optional: avoid double count from same phrase burst
          _speech.stop();
          _isListening = false;

          if (_speakCount >= 3) {
            _triggerSOS();
          } else {
            // resume listening
            Future.delayed(const Duration(milliseconds: 500), () {
              _startListening();
            });
          }
        }
      },
    );
  }

  // 🚨 SOS
  void _triggerSOS() {
    _speech.stop();
    _isListening = false;
    HapticFeedback.heavyImpact();

    Navigator.of(context, rootNavigator: true)
        .pushReplacementNamed('/sos-screen');
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: '/home-dashboard',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/home-dashboard':
            case '/':
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
          if (!AppRoutes.routes.containsKey(routes[index])) return;
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState
                ?.pushReplacementNamed(routes[index]);
          }
        },
      ),
    );
  }
}
