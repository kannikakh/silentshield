import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static Future<Map<String, dynamic>> analyzeText(String text) async {
    final url = Uri.parse("http://127.0.0.1:8000/analyze-call");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to analyze text");
    }
  }
}
