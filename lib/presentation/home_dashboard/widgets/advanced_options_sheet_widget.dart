import 'package:flutter/material.dart';

class AdvancedOptionsSheetWidget extends StatelessWidget {
  final double? motionSensitivity;
  final double? audioSensitivity;
  final ValueChanged<double>? onMotionSensitivityChanged;
  final ValueChanged<double>? onAudioSensitivityChanged;

  const AdvancedOptionsSheetWidget({
    super.key,
    this.motionSensitivity,
    this.audioSensitivity,
    this.onMotionSensitivityChanged,
    this.onAudioSensitivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
