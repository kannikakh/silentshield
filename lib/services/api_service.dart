import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/call_analysis_response.dart';

class ApiService {
  // 🔧 CHANGE THIS BASED ON YOUR SETUP:
  // - Android Emulator: http://10.0.2.2:8000
  // - iOS Simulator: http://localhost:8000
  // - Real Device: http://<YOUR_PC_IP>:8000  (e.g., http://192.168.1.100:8000)
  static const String baseUrl = "http://localhost:8000";

  /// Analyzes call text and returns risk assessment
  ///
  /// Parameters:
  ///   - text: The call transcript/text to analyze
  ///
  /// Returns:
  ///   - CallAnalysisResponse with risk score (0.0 - 1.0)
  ///   - risk: 0.0-0.3 (Safe), 0.3-0.7 (Suspicious), 0.7-1.0 (Scam)
  static Future<CallAnalysisResponse> analyzeCall(String text) async {
    try {
      debugPrint('📱 API: Sending text to analyze: "$text"');

      final response = await http
          .post(
            Uri.parse('$baseUrl/analyze-call'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"text": text}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(
              'API timeout - Backend might be down or network is slow',
            ),
          );

      debugPrint('📊 API Response Code: ${response.statusCode}');
      debugPrint('📊 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = CallAnalysisResponse.fromJson(jsonData);

        debugPrint(
          '✅ Analysis Complete - Risk: ${result.getRiskPercentage()}% (${result.getRiskLevel()})',
        );

        return result;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ API Call Failed: $e');
      rethrow;
    }
  }
}
