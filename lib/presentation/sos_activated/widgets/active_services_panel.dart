import 'package:flutter/material.dart';

class ActiveServicesPanel extends StatelessWidget {
  final bool? isLocationActive;
  final bool? isSmsActive;
  final bool? isRecordingEvidence;

  const ActiveServicesPanel({
    super.key,
    this.isLocationActive,
    this.isSmsActive,
    this.isRecordingEvidence,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
