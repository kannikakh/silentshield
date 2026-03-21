import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/call_analysis_response.dart';
import 'api_service.dart';

class CallAnalysisService {
  /// Analyzes a call transcript and handles the complete flow
  /// This is what you would call when you detect a call or have transcript text
  static Future<CallAnalysisResponse> analyzeCallTranscript(
    String transcriptText,
  ) async {
    try {
      debugPrint('🔍 Starting call analysis for: "$transcriptText"');

      // 1️⃣ Call the backend API
      final analysis = await ApiService.analyzeCall(transcriptText);

      // 2️⃣ Log the results
      debugPrint('📊 Analysis Results:');
      debugPrint('   - Risk Score: ${analysis.getRiskPercentage()}%');
      debugPrint('   - Risk Level: ${analysis.getRiskLevel()}');
      debugPrint('   - Is Scam: ${analysis.isScamLikely()}');
      debugPrint('   - Confidence: ${analysis.confidenceScore}%');

      // 3️⃣ Return the analysis for UI to display
      return analysis;
    } catch (e) {
      debugPrint('❌ Analysis failed: $e');
      rethrow;
    }
  }

  /// Helper to determine UI color based on risk
  /// Use this for the risk meter color
  static Color getRiskColor(double risk) {
    if (risk <= 0.3) {
      return const Color(0xFF00C853); // Green - Safe
    } else if (risk <= 0.7) {
      return const Color(0xFFFFA500); // Orange - Suspicious
    } else {
      return const Color(0xFFD32F2F); // Red - Scam
    }
  }

  /// Helper to get emoji based on risk
  static String getRiskEmoji(double risk) {
    if (risk <= 0.3) {
      return '✅';
    } else if (risk <= 0.7) {
      return '⚠️';
    } else {
      return '🚨';
    }
  }
}

// Example usage in a widget:
/*
class ExampleUsage extends StatefulWidget {
  @override
  State<ExampleUsage> createState() => _ExampleUsageState();
}

class _ExampleUsageState extends State<ExampleUsage> {
  CallAnalysisResponse? _analysis;
  bool _isLoading = false;
  String? _error;

  void _analyzeCallText(String text) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analysis = await CallAnalysisService.analyzeCallTranscript(text);
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });

      // Show alert if scam detected
      if (analysis.isScamLikely()) {
        _showScamAlert(analysis);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showScamAlert(CallAnalysisResponse analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(CallAnalysisService.getRiskEmoji(analysis.risk)),
            const SizedBox(width: 8),
            Text(analysis.getRiskLevel()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Risk Score: ${analysis.getRiskPercentage()}%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (analysis.scamPatterns != null)
              ...analysis.scamPatterns!
                  .map((p) => Text('• $p'))
                  .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _analyzeCallText(
                'Send your OTP now or your account will be blocked',
              ),
              child: const Text('Analyze Sample Scam Text'),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_analysis != null) ...[
              Text('Risk: ${_analysis!.getRiskPercentage()}%'),
              Text('Level: ${_analysis!.getRiskLevel()}'),
              Text('Is Scam: ${_analysis!.isScamLikely()}'),
            ],
            if (_error != null) Text('Error: $_error'),
          ],
        ),
      ),
    );
  }
}
*/
