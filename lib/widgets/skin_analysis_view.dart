import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/SkinConditionResultPage.dart';
import '../models/skin_analysis_model.dart';
import 'patch_painter.dart';

class SkinAnalysisView extends StatefulWidget {
  final Map<String, dynamic> analysisJson;
  final ImageProvider inputImage;
  final Size originalImageSize; // updated name to match PatchPainter
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

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _parsePatches();
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
    final foundTypesSet = _patches
        .where((p) =>
            p.issueType != SkinIssueType.unknown &&
            (p.rect != null || (p.polygon != null && p.polygon!.isNotEmpty)))
        .map((p) => p.issueType)
        .toSet();

    final foundTypes = [
      null,
      ...foundTypesSet.toList()
        ..sort((a, b) => skinIssueTypeDisplayName(a!)
            .compareTo(skinIssueTypeDisplayName(b!)))
    ];

    final visiblePatches = _selectedType == null
        ? _patches
        : _patches.where((p) => p.issueType == _selectedType).toList();

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerSize =
                  Size(constraints.maxWidth, constraints.maxHeight);

              return InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1,
                maxScale: 5,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image(
                        image: widget.inputImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (visiblePatches.isNotEmpty)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PatchPainter(
                            patches: visiblePatches,
                            imageSize: widget.originalImageSize,
                            displaySize: containerSize,
                            selectedType: _selectedType,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildSummaryPanel(_patches),
        if (foundTypes.isNotEmpty)
          Container(
            height: 60,
            width: double.infinity,
            color: Colors.transparent,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: foundTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, idx) {
                final type = foundTypes[idx];
                final selected = _selectedType == type;
                return TextButton(
                  key: ValueKey(type?.toString() ?? "all"),
                  style: TextButton.styleFrom(
                    backgroundColor: selected
                        ? Colors.blue.withOpacity(0.12)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: selected
                          ? const BorderSide(color: Colors.blue, width: 1)
                          : BorderSide.none,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  child: Text(
                    type == null ? "All" : skinIssueTypeDisplayName(type),
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.blue : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryPanel(List<SkinPatch> patches) {
    final Map<SkinIssueType, int> summaryCounts = {};
    for (final patch in patches) {
      if (patch.rect == null &&
          (patch.polygon == null || patch.polygon!.isEmpty)) {
        summaryCounts[patch.issueType] =
            (summaryCounts[patch.issueType] ?? 0) + 1;
      }
    }
    if (summaryCounts.isEmpty) return SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Wrap(
        spacing: 16,
        children: summaryCounts.entries.map((e) {
          return Chip(
            backgroundColor:
                issueColors[e.key]?.withOpacity(0.2) ?? Colors.grey.shade200,
            label: Text(
              "${skinIssueTypeDisplayName(e.key)}: ${e.value}",
              style: TextStyle(
                color: issueColors[e.key] ?? Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
