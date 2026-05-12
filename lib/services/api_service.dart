import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:html' as html; // only used on web to detect host
import 'package:http/http.dart' as http;
import '../models/call_analysis_response.dart';

class ApiService {
  // Determine base URL dynamically on web so requests originate to the
  // development machine where the backend runs. For mobile/desktop use
  // localhost as before.
  static String get baseUrl {
    if (kIsWeb) {
      final loc = html.window.location;
      final host = loc.hostname ?? '';
      final scheme = loc.protocol.replaceAll(':', '');
      // Some browsers resolve "localhost" to IPv6 ::1 which may not
      // be bound by the local backend. Prefer IPv4 loopback when developing
      // locally to avoid "Failed to fetch" from the web client.
      if (host == 'localhost' || host == '::1' || host.isEmpty) {
        return '$scheme://127.0.0.1:8000';
      }
      return '$scheme://$host:8000';
    }
    return 'http://localhost:8000';
  }

  /// Analyzes call text and returns risk assessment
  static Future<CallAnalysisResponse> analyzeCall(String text) async {
    debugPrint('📱 API: Sending text to analyze: "$text"');

<<<<<<< HEAD
      final response = await http
          .post(
            Uri.parse('$baseUrl/analyze-call'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"text": text}),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception(
              'API timeout - Backend might be down or network is slow',
            ),
=======
    int attempts = 0;
    while (true) {
      attempts += 1;
      try {
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
>>>>>>> 8c047fc (updated backend)
          );
          return result;
        } else {
          throw Exception(
            'API Error: ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('❌ API Call Attempt $attempts failed: $e');
        if (attempts >= 2) {
          debugPrint(
            '⚠️ Returning fallback analysis result due to repeated API failures',
          );
          return CallAnalysisResponse(
            transcript: text,
            risk: 0.0,
            scamPatterns: [],
            confidenceScore: 0,
          );
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }
}
