import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/SkinConditionResultPage.dart';
import '../models/skin_analysis_model.dart';
import 'patch_painter.dart';

class SkinAnalysisView extends StatefulWidget {
  final Map<String, dynamic> analysisJson;
  final ImageProvider inputImage;
  final Size originalImageSize;
  final SkinIssueType? selectedType;

  const SkinAnalysisView({
    Key? key,
    required this.analysisJson,
    required this.inputImage,
    required this.originalImageSize,
    this.selectedType,
  }) : super(key: key);

  @override
  State<SkinAnalysisView> createState() => _SkinAnalysisViewState();
}

const Map<SkinIssueType, Color> issueColors = {
  SkinIssueType.acne: Colors.red,
  SkinIssueType.wrinkle: Colors.purple,
  SkinIssueType.darkSpots: Colors.orange,
  SkinIssueType.unknown: Colors.grey,
};

class _SkinAnalysisViewState extends State<SkinAnalysisView> {
  SkinIssueType? _selectedType;
  final TransformationController _transformationController =
      TransformationController();
  late List<SkinPatch> _patches;
  bool _openedResultPage = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _parsePatches();

    // Directly open SkinConditionResultPage after analysisJson is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_openedResultPage) {
        _openedResultPage = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SkinConditionResultPage(
              gradioResult: widget.analysisJson,
            ),
          ),
        );
      }
    });
  }

  void _parsePatches() {
    _patches = SkinPatch.fromJsonAll(widget.analysisJson);
  }

  @override
  void didUpdateWidget(covariant SkinAnalysisView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysisJson != widget.analysisJson) {
      _parsePatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Optionally: show a loader or nothing, since we are navigating away
    return const SizedBox.shrink();
  }
}
