import 'package:flutter/material.dart';

class RiskMeterWidget extends StatelessWidget {
  final double risk;
  final String label;

  const RiskMeterWidget({
    super.key,
    required this.risk,
    required this.label,
  });

  Color getColor() {
    if (risk >= 0.7) return Colors.red;
    if (risk >= 0.4) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: getColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getColor(), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Risk Level: ${label.toUpperCase()}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: getColor(),
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: risk,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(getColor()),
          ),
          const SizedBox(height: 5),
          Text("Risk Score: ${(risk * 100).toInt()}%"),
        ],
      ),
    );
  }
}