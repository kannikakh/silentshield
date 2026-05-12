import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/call_analysis_response.dart';
import 'api_service.dart';
import 'sos_service.dart';

class CallAnalysisService {

  /// ==============================
  /// Analyze Call Transcript
  /// ==============================
  static Future<CallAnalysisResponse> analyzeCallTranscript(
    BuildContext context,
    String transcriptText,
  ) async {

    try {

      debugPrint('🔍 Starting call analysis...');
      debugPrint('📝 Transcript: $transcriptText');

      // ==============================
      // CALL BACKEND
      // ==============================

      final analysis = await ApiService
          .analyzeCall(transcriptText)
          .timeout(const Duration(seconds: 5));

      // ==============================
      // LOG RESULTS
      // ==============================

      debugPrint('📊 Analysis Results');
      debugPrint('Risk Score: ${analysis.getRiskPercentage()}%');
      debugPrint('Risk Level: ${analysis.getRiskLevel()}');
      debugPrint('Is Scam: ${analysis.isScamLikely()}');
      debugPrint('Confidence: ${analysis.confidenceScore ?? 0}%');

      // ==============================
      // SHOW ALERT IF HIGH RISK
      // ==============================

      if (analysis.risk >= 0.75) {

        await showScamAlertDialog(
          context,
          transcriptText,
          analysis,
        );
      }

      return analysis;

    } catch (e, s) {

      debugPrint('❌ Analysis failed: $e');

      debugPrintStack(stackTrace: s);

      // SAFE FALLBACK
      return CallAnalysisResponse(
        transcript: transcriptText,
        risk: 0.0,
        scamPatterns: [],
        confidenceScore: 0,
      );
    }
  }

  /// ==============================
  /// Risk Color
  /// ==============================
  static Color getRiskColor(double risk) {

    if (risk <= 0.3) {

      return const Color(0xFF00C853);

    } else if (risk <= 0.7) {

      return const Color(0xFFFFA500);

    } else {

      return const Color(0xFFD32F2F);
    }
  }

  /// ==============================
  /// Risk Emoji
  /// ==============================
  static String getRiskEmoji(double risk) {

    if (risk <= 0.3) {

      return '✅';

    } else if (risk <= 0.7) {

      return '⚠️';

    } else {

      return '🚨';
    }
  }

  /// ==============================
  /// Report Scam Call
  /// ==============================
  static Future<void> reportScamCall({
    required String transcript,
    required double risk,
  }) async {

    try {

      await FirebaseFirestore.instance
          .collection('reported_calls')
          .add({

        'transcript': transcript,

        'risk': risk,

        'reportedAt': FieldValue.serverTimestamp(),

        'status': 'reported',
      });

      debugPrint('✅ Scam call reported');

    } catch (e) {

      debugPrint('❌ Report failed: $e');
    }
  }

  /// ==============================
  /// Scam Alert Dialog
  /// ==============================
  static Future<void> showScamAlertDialog(
    BuildContext context,
    String transcript,
    CallAnalysisResponse analysis,
  ) async {

    return showDialog(

      context: context,

      barrierDismissible: false,

      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          title: Row(
            children: const [

              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  "Potential Scam Detected",
                ),
              ),
            ],
          ),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const Text(
                "This call appears suspicious.",
              ),

              const SizedBox(height: 12),

              Text(
                "Risk Level: ${analysis.getRiskLevel()}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Confidence: ${(analysis.confidenceScore ?? 0).toStringAsFixed(1)}%",
              ),
            ],
          ),

          actions: [

            /// IGNORE
            TextButton(

              onPressed: () {

                Navigator.pop(context);

              },

              child: const Text(
                "Ignore",
              ),
            ),

            /// REPORT
            ElevatedButton.icon(

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),

              onPressed: () async {

                Navigator.pop(context);

                await reportScamCall(
                  transcript: transcript,
                  risk: analysis.risk,
                );

                if (context.mounted) {

                  ScaffoldMessenger.of(context).showSnackBar(

                    const SnackBar(
                      content: Text(
                        'Scam call reported successfully',
                      ),
                    ),
                  );
                }
              },

              icon: const Icon(Icons.report),

              label: const Text("Report"),
            ),

            /// NOTIFY
            ElevatedButton.icon(

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),

              onPressed: () async {

                Navigator.pop(context);

                try {

                  await SosService().sendSos();

                  if (context.mounted) {

                    ScaffoldMessenger.of(context).showSnackBar(

                      const SnackBar(
                        content: Text(
                          'Emergency contacts notified',
                        ),
                      ),
                    );
                  }

                } catch (e) {

                  debugPrint('❌ SOS failed: $e');
                }
              },

              icon: const Icon(
                Icons.notification_important,
              ),

              label: const Text(
                "Notify",
              ),
            ),
          ],
        );
      },
    );
  }
}