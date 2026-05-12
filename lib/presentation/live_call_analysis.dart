import 'package:flutter/material.dart';
import 'package:silentshield/services/speech_recognition_service.dart';
import 'package:silentshield/services/call_analysis_service.dart';
import 'package:silentshield/models/call_analysis_response.dart';

class LiveCallAnalysis extends StatefulWidget {
  const LiveCallAnalysis({super.key});

  @override
  State<LiveCallAnalysis> createState() => _LiveCallAnalysisState();
}

class _LiveCallAnalysisState extends State<LiveCallAnalysis> {
  late SpeechRecognitionService _speechService;

  String _recognizedText = '';
  CallAnalysisResponse? _latestAnalysis;
  bool _isListening = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _speechService = SpeechRecognitionService();

    // Set up callbacks
    _speechService.onTextRecognized = (text) {
      if (!mounted) return;
      setState(() {
        _recognizedText = text;
      });

      // Analyze text in real-time
      if (text.isNotEmpty && text.length > 3) {
        _analyzeText(text);
      }
    };

    _speechService.onListeningStateChanged = (isListening) {
      if (!mounted) return;
      setState(() {
        _isListening = isListening;
      });
    };

    _speechService.onError = (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error;
      });
      _showSnackBar(error, Colors.red);
    };
  }

  Future<void> _analyzeText(String text) async {
    try {
<<<<<<< HEAD
      final analysis = await CallAnalysisService.analyzeCallTranscript(
        context,
        text,
      );

=======
      final analysis = await CallAnalysisService.analyzeCallTranscript(text);
      if (!mounted) return;
>>>>>>> 8c047fc (updated backend)
      setState(() {
        _latestAnalysis = analysis;
        _errorMessage = null;
      });

      // Show alert if high risk detected
      if (analysis.isScamLikely()) {
        _showHighRiskAlert(analysis);
      }
    } catch (e) {
      print('❌ Analysis error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar('Analysis error: ${e.toString()}', Colors.red);
    }
  }

  void _showHighRiskAlert(CallAnalysisResponse analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: [
            const Text(
              '🚨 HIGH RISK DETECTED',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Level: ${(analysis.risk * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Detected Patterns:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (analysis.scamPatterns != null)
              for (var pattern in analysis.scamPatterns!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Text('🚩 ', style: TextStyle(fontSize: 16)),
                      Expanded(child: Text(pattern)),
                    ],
                  ),
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _triggerSOS();
            },
            icon: const Icon(Icons.phone),
            label: const Text('Send SOS'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Triggered 🆘'),
        content: const Text('Emergency contacts have been notified!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startListening() async {
    setState(() {
      _recognizedText = '';
      _latestAnalysis = null;
      _errorMessage = null;
    });

    await _speechService.startListening();
  }

  Future<void> _stopListening() async {
    await _speechService.stopListening();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel speech service and clear callbacks to avoid late callbacks
    _speechService.cancel();
    _speechService.onTextRecognized = null;
    _speechService.onListeningStateChanged = null;
    _speechService.onError = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Live Call Analysis'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _isListening ? Colors.green.shade50 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isListening ? 'Listening...' : 'Ready to listen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isListening
                            ? Colors.green
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isListening ? null : _startListening,
                  icon: const Icon(Icons.mic),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isListening ? _stopListening : null,
                  icon: const Icon(Icons.stop_circle),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            const SizedBox(height: 16),

            // Recognized Text
            const Text(
              'Recognized Text',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _recognizedText.isEmpty
                    ? 'Awaiting speech...'
                    : _recognizedText,
                style: TextStyle(
                  fontSize: 16,
                  color: _recognizedText.isEmpty
                      ? Colors.grey.shade500
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Analysis Results
            if (_latestAnalysis != null) ...[
              const Text(
                'Real-Time Analysis',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildAnalysisCard(_latestAnalysis!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(CallAnalysisResponse analysis) {
    final riskColor = analysis.risk <= 0.3
        ? Colors.green
        : analysis.risk <= 0.7
        ? Colors.orange
        : Colors.red;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: riskColor.withOpacity(0.05),
          border: Border.all(color: riskColor.withOpacity(0.3), width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Risk Score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
                Text(
                  '${analysis.getRiskPercentage()}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: analysis.risk,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                analysis.getRiskLevel(),
                style: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (analysis.scamPatterns != null &&
                analysis.scamPatterns!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detected Patterns:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ...analysis.scamPatterns!.map(
                    (pattern) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Text('🚩 ', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Text(
                              pattern,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${analysis.confidenceScore}%',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
