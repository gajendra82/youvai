import 'package:flutter/material.dart';

abstract class SkinAnalysisEvent {}

class LoadSkinAnalysis extends SkinAnalysisEvent {
  final Map<String, dynamic> analysisJson;
  final ImageProvider inputImage;
  LoadSkinAnalysis({required this.analysisJson, required this.inputImage});
}
