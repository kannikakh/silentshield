import 'dart:convert';
import 'package:http/http.dart' as http;

class SosSmsService {
  // ✅ Change this to your backend URL
  // If using local PC with Android emulator:
  // http://10.0.2.2:8000
  // If using local PC with real phone:
  // Use your PC IP like: http://192.168.x.x:8000
  static const String baseUrl = "http://192.168.29.173:8000";

  static Future<void> sendSOS({
    required String message,
    required List<String> numbers,
  }) async {
    final url = Uri.parse("$baseUrl/send-sos-sms");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message, "numbers": numbers}),
    );

    if (response.statusCode != 200) {
      throw Exception("SMS Failed: ${response.body}");
    }
  }
}
