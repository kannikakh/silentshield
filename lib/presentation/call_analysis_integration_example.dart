import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';

/// Example: How to integrate backend call analysis into your voice shield screen
///
/// This shows how to replace mock data with real API calls
///
/// Key changes:
/// - Load analysis from API when call is received
/// - Update UI based on real risk scores
/// - Show alerts based on analysis results

class CallAnalysisIntegrationExample extends StatefulWidget {
  final String? callText; // Could come from speech-to-text

  const CallAnalysisIntegrationExample({super.key, this.callText});

  @override
  State<CallAnalysisIntegrationExample> createState() =>
      _CallAnalysisIntegrationExampleState();
}

class _CallAnalysisIntegrationExampleState
    extends State<CallAnalysisIntegrationExample> {
  CallAnalysisResponse? _analysis;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // If we have call text on init, analyze it
    if (widget.callText != null && widget.callText!.isNotEmpty) {
      _analyzeCall(widget.callText!);
    }
  }

  Future<void> _analyzeCall(String text) async {
    // Avoid analyzing if already loading
    if (_isLoading) return;

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

      // Show alert if risky
      if (analysis.isScamLikely()) {
        _showScamAlert(analysis);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showScamAlert(CallAnalysisResponse analysis) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: analysis.risk > 0.7
            ? Colors.red[50]
            : Colors.orange[50],
        title: Row(
          children: [
            Text(
              CallAnalysisService.getRiskEmoji(analysis.risk),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(analysis.getRiskLevel()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Risk percentage
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CallAnalysisService.getRiskColor(
                  analysis.risk,
                ).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Risk Score:'),
                  Text(
                    '${analysis.getRiskPercentage()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Confidence
            if (analysis.confidenceScore != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Confidence:'),
                  Text('${analysis.confidenceScore}%'),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Scam patterns
            if (analysis.scamPatterns != null &&
                analysis.scamPatterns!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detected Patterns:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...analysis.scamPatterns!.map(
                    (pattern) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Text('• '),
                          Expanded(child: Text(pattern)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          if (analysis.risk > 0.7)
            ElevatedButton(
              onPressed: () {
                // Trigger SOS when scam is confirmed
                Navigator.pop(context);
                _triggerSOS();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Send SOS'),
            ),
        ],
      ),
    );
  }

  void _triggerSOS() {
    // Integration with SOS Service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 SOS Alert Sent'),
        backgroundColor: Colors.red,
      ),
    );
    // sosService.sendSos(); // Uncomment when ready
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Analysis')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          children: [
            // Test input section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Call Analysis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _analyzeCall(
                        'Send your OTP now or your account will be blocked',
                      ),
                      icon: const Icon(Icons.security),
                      label: const Text('Test: Scam Call'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _analyzeCall(
                        'Hi this is John from customer support, how are you today?',
                      ),
                      icon: const Icon(Icons.shield),
                      label: const Text('Test: Safe Call'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Analysis results section
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Failed',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: Colors.red[700])),
                  ],
                ),
              )
            else if (_analysis != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CallAnalysisService.getRiskColor(
                    _analysis!.risk,
                  ).withOpacity(0.1),
                  border: Border.all(
                    color: CallAnalysisService.getRiskColor(_analysis!.risk),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Risk Level',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              _analysis!.getRiskLevel(),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: CallAnalysisService.getRiskColor(
                                      _analysis!.risk,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                        Text(
                          CallAnalysisService.getRiskEmoji(_analysis!.risk),
                          style: const TextStyle(fontSize: 48),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Risk Score',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              '${_analysis!.getRiskPercentage()}%',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        if (_analysis!.confidenceScore != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confidence',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                '${_analysis!.confidenceScore}%',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (_analysis!.scamPatterns != null &&
                        _analysis!.scamPatterns!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Detected Patterns',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...(_analysis!.scamPatterns!.map(
                        (pattern) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $pattern'),
                        ),
                      )),
                    ],
                    const SizedBox(height: 16),
                    if (_analysis!.isScamLikely())
                      ElevatedButton(
                        onPressed: _triggerSOS,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Send SOS Alert'),
                      ),
                  ],
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('No analysis yet'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
