class CallAnalysisResponse {
  final String transcript;
  final double risk;
  final List<String>? scamPatterns;
  final int? confidenceScore;

  CallAnalysisResponse({
    required this.transcript,
    required this.risk,
    this.scamPatterns,
    this.confidenceScore,
  });

  factory CallAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return CallAnalysisResponse(
      transcript: json['transcript'] ?? '',
      risk: (json['risk'] ?? 0).toDouble(),
      scamPatterns: json['scamPatterns'] != null
          ? List<String>.from(json['scamPatterns'])
          : null,
      confidenceScore: json['confidenceScore'],
    );
  }

  // Get risk level based on score
  String getRiskLevel() {
    if (risk <= 0.3) {
      return "Safe";
    } else if (risk <= 0.7) {
      return "Suspicious";
    } else {
      return "High Risk";
    }
  }

  // Get risk percentage (0-100)
  int getRiskPercentage() {
    return (risk * 100).toInt();
  }

  // Check if it's likely a scam
  bool isScamLikely() {
    return risk > 0.7;
  }
}
