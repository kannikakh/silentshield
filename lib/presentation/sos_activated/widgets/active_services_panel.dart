import 'package:flutter/material.dart';

class ActiveServicesPanel extends StatelessWidget {
  final bool? isLocationActive;
  final bool? isSmsActive;
  final bool? isRecordingEvidence;

  const ActiveServicesPanel({
    Key? key,
    this.isLocationActive,
    this.isSmsActive,
    this.isRecordingEvidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
