import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/skin_analysis_model.dart';
import 'package:path/path.dart';

// Helper class for face analysis point overlay
class _FacePoint {
  final String name;
  final double dx;
  final double dy;
  final String? valueText;
  final String? detailText;

  const _FacePoint({
    required this.name,
    required this.dx,
    required this.dy,
    this.valueText,
    this.detailText,
  });
}

class FaceViewPage extends StatefulWidget {
  @override
  State<FaceViewPage> createState() => _FaceViewPageState();
}

class _FaceViewPageState extends State<FaceViewPage> {
  int _selectedTab = 0;
  int? _highlightedIndex;
  File? _imageFile;
  Map<String, dynamic>? _analysisJson;
  bool _loading = false;
  String? _error;
  List<_FacePoint> _points = [];

  @override
  void initState() {
    super.initState();
    _pickInitialImage();
  }

  Future<void> _pickInitialImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      preferredCameraDevice: CameraDevice.front,
    );
    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      setState(() {
        _loading = true;
      });
      await _analyzeImage(_imageFile!);
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    Map<String, dynamic>? ailabData;
    try {
      final uri = Uri.parse(
          "https://www.ailabapi.com/api/portrait/analysis/skin-analysis-pro");
      final req = http.MultipartRequest('POST', uri);
      req.headers['ailabapi-api-key'] =
          'qaZ9TlSGKuaXR1D06DbIOCW380RUrdek7iVxmHVYJs9FniA3U5cOBkPtNLrlJF2h';
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final streamedResp = await req.send();
      final resp = await http.Response.fromStream(streamedResp);

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is Map<String, dynamic>) {
          ailabData = decoded;
        }
      }
    } catch (e) {
      ailabData = null;
    }

    final points = _facePointsFromAILAB(result: ailabData?['result']);

    setState(() {
      _analysisJson = ailabData;
      _points = points;
      _loading = false;
      _error = (_analysisJson == null)
          ? "No face analysis detected. Try again."
          : null;
    });
  }

  List<_FacePoint> _facePointsFromAILAB({Map<String, dynamic>? result}) {
    if (result == null) return [];
    // Map API fields to overlays (adjust dx/dy for your UI)
    return [
      _FacePoint(
        name: "Skin Age",
        dx: 0.50,
        dy: 0.13,
        valueText: result['skin_age']?['value']?.toString(),
        detailText: "Estimated skin age.",
      ),
      _FacePoint(
        name: "Eye Pouch",
        dx: 0.28,
        dy: 0.40,
        valueText: _severityText(result['eye_pouch_severity']?['value']),
        detailText: "Under-eye puffiness.",
      ),
      _FacePoint(
        name: "Dark Circle",
        dx: 0.28,
        dy: 0.47,
        valueText: _severityText(result['dark_circle_severity']?['value']),
        detailText: "Dark circle severity.",
      ),
      _FacePoint(
        name: "Forehead Wrinkle",
        dx: 0.49,
        dy: 0.21,
        valueText: _severityText(result['forehead_wrinkle']?['value']),
        detailText: "Forehead wrinkle presence.",
      ),
      _FacePoint(
        name: "Crow's Feet",
        dx: 0.16,
        dy: 0.29,
        valueText: _severityText(result['crows_feet']?['value']),
        detailText: "Wrinkles near eye corners.",
      ),
      _FacePoint(
        name: "Eye Fine Lines",
        dx: 0.32,
        dy: 0.38,
        valueText: _severityText(result['eye_finelines_severity']?['value']),
        detailText: "Fine lines near eyes.",
      ),
      _FacePoint(
        name: "Glabella Wrinkle",
        dx: 0.50,
        dy: 0.32,
        valueText: _severityText(result['glabella_wrinkle']?['value']),
        detailText: "Wrinkle between eyebrows.",
      ),
      _FacePoint(
        name: "Nasolabial Fold",
        dx: 0.46,
        dy: 0.62,
        valueText: _severityText(result['nasolabial_fold_severity']?['value']),
        detailText: "Smile lines severity.",
      ),
      // Add more if your API returns additional fields
    ];
  }

  static String _severityText(dynamic val) {
    if (val == null) return '-';
    switch (val.toString()) {
      case '0':
        return 'None';
      case '1':
        return 'Mild';
      case '2':
        return 'Moderate';
      case '3':
        return 'Severe';
      default:
        return val.toString();
    }
  }

  void _showPointSheet(int index, context) {
    setState(() => _highlightedIndex = index);
    final pt = _points[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pt.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF7C6CC6)),
            ),
            if (pt.valueText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: Text("Severity: ${pt.valueText}",
                    style:
                        const TextStyle(fontSize: 16, color: Colors.black87)),
              ),
            if (pt.detailText != null)
              Text(pt.detailText!,
                  style: const TextStyle(fontSize: 15, color: Colors.black54)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6CC6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      setState(() => _highlightedIndex = null);
    });
  }

  _showOverviewSheet(context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Full Overview",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF7C6CC6)),
              ),
              const SizedBox(height: 12),
              ..._points.map((pt) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(pt.name,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(pt.valueText ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C6CC6))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  double _tabSheetHeight(BuildContext context) {
    switch (_selectedTab) {
      case 0:
        return 220;
      case 1:
        return 340;
      case 2:
        return 210;
      case 3:
        return 210;
      default:
        return 220;
    }
  }

  Widget _tabPanel(BuildContext context) {
    switch (_selectedTab) {
      case 0:
        return _OverviewPanel(points: _points, analysisJson: _analysisJson);
      case 1:
        return _SymptomsPanel(points: _points, analysisJson: _analysisJson);
      case 2:
        return _TreatmentsPanel();
      case 3:
        return _SpecialistPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTabButton(String text, int index) {
    final bool selected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFFEEEAFE) : Colors.white,
          foregroundColor: selected ? const Color(0xFF7C6CC6) : Colors.black87,
          side: BorderSide(
            color: selected ? const Color(0xFF7C6CC6) : Colors.black12,
            width: 2,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        ),
        onPressed: () => setState(() => _selectedTab = index),
        child: Text(
          text,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: selected ? const Color(0xFF7C6CC6) : Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _imageFile == null
              ? Center(
                  child: ElevatedButton(
                    onPressed: _pickInitialImage,
                    child: const Text('Scan Face'),
                  ),
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final height = constraints.maxHeight;
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              ..._points.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final pt = entry.value;
                                final left = pt.dx * width - 18;
                                final top = pt.dy * height - 18;
                                return Positioned(
                                  left: left,
                                  top: top,
                                  child: GestureDetector(
                                    onTap: () => _showPointSheet(idx, context),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width:
                                          _highlightedIndex == idx ? 36 : 28,
                                      height:
                                          _highlightedIndex == idx ? 36 : 28,
                                      decoration: BoxDecoration(
                                        color: _highlightedIndex == idx
                                            ? const Color(0xFF7C6CC6)
                                            : Colors.white,
                                        border: Border.all(
                                          color: _highlightedIndex == idx
                                              ? const Color(0xFF7C6CC6)
                                              : Colors.deepPurple,
                                          width: 2,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        boxShadow: [
                                          if (_highlightedIndex == idx)
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            )
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          pt.name[0],
                                          style: TextStyle(
                                            color: _highlightedIndex == idx
                                                ? Colors.white
                                                : Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
                    ),
                    // Top bar
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 56),
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 28,
                            child: Icon(Icons.face_retouching_natural,
                                color: Colors.deepPurple[300], size: 34),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.black54),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: _tabSheetHeight(context),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(30)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTabButton("Overview", 0),
                                _buildTabButton("Symptoms", 1),
                                _buildTabButton("Treatments", 2),
                                _buildTabButton("Specialist", 3),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: _tabPanel(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C6CC6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _showOverviewSheet(context),
                                child: const Text(
                                  "View All Overview",
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// Panels for bottom sheet

class _OverviewPanel extends StatelessWidget {
  final List<_FacePoint> points;
  final Map<String, dynamic>? analysisJson;

  const _OverviewPanel({required this.points, this.analysisJson});

  @override
  Widget build(BuildContext context) {
    final skinAge = points.firstWhere((p) => p.name == "Skin Age",
        orElse: () => _FacePoint(name: "", dx: 0, dy: 0)).valueText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Skin Age: ${skinAge ?? '-'}",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF7C6CC6)),
          ),
          const SizedBox(height: 10),
          ...points
              .where((pt) => pt.name != "Skin Age")
              .map((pt) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(pt.name),
                        Text(pt.valueText ?? "-",
                            style: const TextStyle(
                                color: Color(0xFF7C6CC6),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }
}

class _SymptomsPanel extends StatelessWidget {
  final List<_FacePoint> points;
  final Map<String, dynamic>? analysisJson;

  const _SymptomsPanel({required this.points, this.analysisJson});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(
            "Detailed Analysis",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Text(
            "Based on AI skin detection",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 12),
        ...points
            .where((pt) =>
                pt.valueText != null &&
                pt.valueText != '-' &&
                pt.valueText != 'None' &&
                pt.name != "Skin Age")
            .map(
              (pt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pt.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      pt.valueText!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C6CC6)),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 18),
        const Text(
          "Be aware",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _tagChip("Dust"),
            _tagChip("Dehydration"),
            _tagChip("Stress"),
            _tagChip("Hair Products"),
            _tagChip("Touching Face", color: Colors.deepOrange),
          ],
        ),
      ],
    );
  }

  static Widget _tagChip(String label, {Color color = Colors.black45}) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    );
  }
}

class _TreatmentsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Text(
        "Recommended treatments and skincare routines.",
        style: TextStyle(fontSize: 15, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SpecialistPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Text(
        "Specialist advice and contact.",
        style: TextStyle(fontSize: 15, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }
}