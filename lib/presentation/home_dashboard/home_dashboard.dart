import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 🔴 Speech + Local storage
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Location
import 'package:geolocator/geolocator.dart';

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

  // ✅ Location flags
  // ignore: unused_field
  bool _locationSaved = false;

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

    // ✅ Location permission + store location in SharedPreferences
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestLocationPermissionAndStore();
    });
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

  // ✅ LOCATION: ask permission + store lat,lng,mapLink
  Future<void> _requestLocationPermissionAndStore() async {
    try {
      // ✅ 1) Check service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("❌ Location services are OFF");
        return;
      }

      // ✅ 2) Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        debugPrint("❌ Location permission denied");
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("❌ Location permission denied forever");
        return;
      }

      // ✅ 3) Get current location
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = pos.latitude;
      final lng = pos.longitude;
      final mapLink = "https://www.google.com/maps?q=$lat,$lng";

      // ✅ 4) Save in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble("lat", lat);
      await prefs.setDouble("lng", lng);
      await prefs.setString("mapLink", mapLink);

      setState(() => _locationSaved = true);

      debugPrint("✅ Location stored in prefs: $lat , $lng");
      debugPrint("✅ Map link: $mapLink");
    } catch (e) {
      debugPrint("❌ Location store failed: $e");
    }
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

    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed('/sos-screen');
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
            navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
      ),
    );
  }
}
