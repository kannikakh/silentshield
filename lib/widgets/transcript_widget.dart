import 'package:flutter/material.dart';

class TranscriptWidget extends StatelessWidget {
  final String text;

  const TranscriptWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.record_voice_over, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.isEmpty ? "No transcript available..." : text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
