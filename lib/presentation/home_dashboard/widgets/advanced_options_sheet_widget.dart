import 'package:flutter/material.dart';

class AdvancedOptionsSheetWidget extends StatelessWidget {
  final double? motionSensitivity;
  final double? audioSensitivity;
  final ValueChanged<double>? onMotionSensitivityChanged;
  final ValueChanged<double>? onAudioSensitivityChanged;

  const AdvancedOptionsSheetWidget({
    Key? key,
    this.motionSensitivity,
    this.audioSensitivity,
    this.onMotionSensitivityChanged,
    this.onAudioSensitivityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
