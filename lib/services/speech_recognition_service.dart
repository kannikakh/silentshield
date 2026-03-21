import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechRecognitionService {
  static final SpeechRecognitionService _instance =
      SpeechRecognitionService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';

  // Callbacks
  Function(String)? onTextRecognized;
  Function(bool)? onListeningStateChanged;
  Function(String)? onError;

  factory SpeechRecognitionService() {
    return _instance;
  }

  SpeechRecognitionService._internal();

  // Check if speech-to-text is available
  Future<bool> initialize() async {
    try {
      print('🎙️ Initializing speech recognition...');
      bool available = await _speechToText.initialize(
        onError: (error) {
          print('❌ Speech error: $error');
          onError?.call('Error: ${error.errorMsg}');
        },
        onStatus: (status) {
          print('🎙️ Speech status: $status');
          if (status == 'listening') {
            print('✅ Microphone permission granted - now listening!');
          }
        },
      );
      print('🎙️ Speech recognition initialized: $available');
      return available;
    } catch (e) {
      print('❌ Failed to initialize speech recognition: $e');
      onError?.call('Error initializing speech: $e');
      return false;
    }
  }

  // Start listening
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      print('🎙️ Starting speech recognition...');

      // Initialize first (triggers browser permission on first use)
      bool available = await initialize();
      if (!available) {
        onError?.call('Speech recognition not available');
        return;
      }

      _recognizedText = '';
      _isListening = true;
      onListeningStateChanged?.call(true);
      print('🎙️ Listening started');

      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _recognizedText = result.recognizedWords;
          print('🎙️ Recognized: $_recognizedText');
          print('🎙️ Is final: ${result.finalResult}');

          onTextRecognized?.call(_recognizedText);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: (level) {
          print('🎙️ Sound level: $level');
        },
      );
    } catch (e) {
      print('❌ Error starting listening: $e');
      onError?.call('Error: $e');
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      onListeningStateChanged?.call(false);
      print('🎙️ Listening stopped');
    } catch (e) {
      print('❌ Error stopping listening: $e');
      onError?.call('Error stopping: $e');
    }
  }

  // Cancel
  Future<void> cancel() async {
    try {
      await _speechToText.cancel();
      _isListening = false;
      _recognizedText = '';
      onListeningStateChanged?.call(false);
    } catch (e) {
      print('❌ Error canceling: $e');
    }
  }

  // Getters
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  bool get isAvailable => _speechToText.isAvailable;

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      var locales = await _speechToText.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      print('❌ Error getting languages: $e');
      return [];
    }
  }
}
