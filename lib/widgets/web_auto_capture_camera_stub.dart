import 'dart:typed_data';
import 'package:flutter/material.dart';

class WebAutoCaptureCamera extends StatelessWidget {
  final void Function(Uint8List bytes, Size size) onCaptured;
  final double targetCenterToleranceRatio;
  final double minFaceBoxRatio;
  final double maxFaceBoxRatio;
  final int stableFramesRequired;

  const WebAutoCaptureCamera({
    super.key,
    required this.onCaptured,
    this.targetCenterToleranceRatio = 0.12,
    this.minFaceBoxRatio = 0.28,
    this.maxFaceBoxRatio = 0.55,
    this.stableFramesRequired = 10,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
