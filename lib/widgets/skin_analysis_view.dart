import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/SkinConditionResultPage.dart';
import '../models/skin_analysis_model.dart';
import 'patch_painter.dart';

class SkinAnalysisView extends StatefulWidget {
  final Map<String, dynamic> analysisJson;
  final ImageProvider inputImage;
  final Size originalImageSize;
  final SkinIssueType? selectedType;
  final Map<String, dynamic>? gradioResult;

  final Future<Map<String, dynamic>?> Function()? onViewPercentageSummary;
  final void Function(Map<String, dynamic>?)? onGradioResult;

  const SkinAnalysisView({
    Key? key,
    required this.analysisJson,
    required this.inputImage,
    required this.originalImageSize,
    required this.gradioResult,
    this.selectedType,
    this.onViewPercentageSummary,
    this.onGradioResult,
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

  bool _uploading = false;

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

    return Scaffold(
        bottomNavigationBar: widget.analysisJson != null
            ? Container(
                height: 80,
                alignment: Alignment.bottomCenter,

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.gradioResult != null ||
                        widget.onViewPercentageSummary != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.analytics),
                            label: _uploading
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors
                                              .white, 
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text("Getting Results..."),
                                    ],
                                  )
                                : const Text("View Percentage & Summary"),
                            onPressed: _uploading
                                ? () {
                                    print("Already uploading, please wait...");
                                  }
                                : () async {
                                    print("View Percentage & Summary pressed");
                                    Map<String, dynamic>? result =
                                        widget.gradioResult;
                                    if (widget.onViewPercentageSummary !=
                                            null &&
                                        widget.gradioResult == null) {
                                      setState(() => _uploading = true);
                                      result = await widget
                                          .onViewPercentageSummary!();
                                      setState(() => _uploading = false);
                                      if (result != null &&
                                          widget.onGradioResult != null) {
                                        widget.onGradioResult!(result);
                                      }
                                    }
                                    print("Gradio result: $result");
                                    if (result != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SkinConditionResultPage(
                                            gradioResult: result!,
                                            patchJson: widget.analysisJson,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : SizedBox(
                height: 0,
              ),
        body: Column(
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
                          child: Container(
                            color: Colors.black,
                            child: Image(
                              image: widget.inputImage,
                              fit: BoxFit.contain,
                            ),
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
                padding: EdgeInsets.only(top: 10),
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
                    final text =
                        type == null ? "All" : skinIssueTypeDisplayName(type);
                    final selectedGradient = LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        // Theme.of(context).colorScheme.secondary,
                        // Theme.of(context).colorScheme.secondary.withOpacity(0.9),
                        // Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                        // Theme.of(context).primaryColor.withOpacity(0.7),
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor,
                      ],
                    );
                    final unselectedGradient = const LinearGradient(
                      colors: [Colors.white, Colors.white],
                    );
                    return Container(
                      key: ValueKey(type?.toString() ?? "all"),
                      decoration: BoxDecoration(
                        gradient:
                            selected ? selectedGradient : unselectedGradient,
                        borderRadius: BorderRadius.circular(25),
                        border: selected
                            ? Border.all(color: Colors.blue, width: 1)
                            : Border.all(color: Colors.black, width: 1),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedType = type;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Center(
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: selected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ));
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
