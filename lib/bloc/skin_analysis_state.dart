import 'package:flutter/material.dart';
import '../models/skin_analysis_model.dart';

abstract class SkinAnalysisState {}

class SkinAnalysisInitial extends SkinAnalysisState {}

class SkinAnalysisLoaded extends SkinAnalysisState {
  final List<SkinPatch> patches;
  final ImageProvider image;
  SkinAnalysisLoaded({required this.patches, required this.image});
}

class SkinAnalysisError extends SkinAnalysisState {
  final String message;
  SkinAnalysisError(this.message);
}
