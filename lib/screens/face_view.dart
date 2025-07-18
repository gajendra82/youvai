import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FaceViewPage extends StatefulWidget {
  @override
  State<FaceViewPage> createState() => _FaceViewPageState();
}

class _FaceViewPageState extends State<FaceViewPage> {
  int _selectedTab = 1; // 0: Overview, 1: Symptoms, 2: Treatments, 3: Specialist

  final List<_FacePoint> _points = [
    _FacePoint(name: "Acne", dx: 0.5, dy: 0.28),
    _FacePoint(name: "Papules", dx: 0.46, dy: 0.4),
    _FacePoint(name: "Cyst", dx: 0.54, dy: 0.5),
    _FacePoint(name: "Bumps", dx: 0.52, dy: 0.62),
  ];
  int? _highlightedIndex;

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _pickInitialImage();
  }

  Future<void> _pickInitialImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showPointSheet(int index) {
    setState(() => _highlightedIndex = index);
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
              _points[index].name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            const Text(
              "Detailed info about this skin issue, possible causes, and suggestions for care.",
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6CC6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      setState(() => _highlightedIndex = null);
    });
  }

  void _showOverviewSheet() {
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
          children: const [
            Text(
              "Full Overview",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 12),
            Text(
              "Here is the full overview of your skin analysis and recommendations.",
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Returns height based on tab and content
  double _tabSheetHeight(BuildContext context) {
    // Customize heights per tab as needed
    switch (_selectedTab) {
      case 0:
        return 170; // Overview
      case 1:
        return 330; // Symptoms (tallest)
      case 2:
        return 170; // Treatments
      case 3:
        return 170; // Specialist
      default:
        return 200;
    }
  }

  Widget _tabPanel(BuildContext context) {
    switch (_selectedTab) {
      case 0:
        return _OverviewPanel();
      case 1:
        return _SymptomsPanel();
      case 2:
        return _TreatmentsPanel();
      case 3:
        return _SpecialistPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      body: _imageFile == null
          ? Center(
              child: ElevatedButton(
                onPressed: _pickInitialImage,
                child: const Text('Scan Face'),
              ),
            )
          : Stack(
              children: [
                // Face image with points overlay
                Positioned.fill(
                  top: 0,
                  // bottom: MediaQuery.of(context).size.height * 0.38,
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
                                onTap: () => _showPointSheet(idx),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: _highlightedIndex == idx ? 36 : 28,
                                  height: _highlightedIndex == idx ? 36 : 28,
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
                                    borderRadius: BorderRadius.circular(100),
                                    boxShadow: [
                                      if (_highlightedIndex == idx)
                                        BoxShadow(
                                          color: Colors.deepPurple.withOpacity(0.3),
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
                        icon: const Icon(Icons.more_vert, color: Colors.black54),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // Dynamic Bottom Sheet UI - floating and overlays image
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: _tabSheetHeight(context),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                        // Tabs
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
                        // Panel
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: _tabPanel(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // View All Overview Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C6CC6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _showOverviewSheet,
                            child: const Text(
                              "View All Overview",
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildTabButton(String text, int index) {
    final bool selected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? const Color(0xFFEEEAFE) : Colors.white,
          foregroundColor: selected
              ? const Color(0xFF7C6CC6)
              : Colors.black87,
          side: BorderSide(
            color: selected
                ? const Color(0xFF7C6CC6)
                : Colors.black12,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        ),
        onPressed: () => setState(() => _selectedTab = index),
        child: Text(
          text,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: selected
                  ? const Color(0xFF7C6CC6)
                  : Colors.black87),
        ),
      ),
    );
  }
}

// Dummy tab panels below, you can expand as needed

class _OverviewPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Text(
        "General overview about your skin health.",
        style: TextStyle(fontSize: 15, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SymptomsPanel extends StatelessWidget {
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
        _progressRow(
            "Crusting of skin bumps", 0.3, Colors.blue, "Ease", Colors.blue),
        const SizedBox(height: 7),
        _progressRow(
            "Cysts", 0.4, Colors.green, "Gentle", Colors.green),
        const SizedBox(height: 7),
        _progressRow(
            "Papules", 0.8, Colors.deepOrange, "Strong", Colors.deepOrange),
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

  static Widget _progressRow(String label, double value, Color barColor,
      String status, Color statusColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          status,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: statusColor),
        ),
      ],
    );
  }

  static Widget _tagChip(String label, {Color color = Colors.black45}) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        label,
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 13),
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

// Face point data class
class _FacePoint {
  final String name;
  final double dx;
  final double dy;

  const _FacePoint({required this.name, required this.dx, required this.dy});
}