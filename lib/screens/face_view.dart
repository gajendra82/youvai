import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:skin_assessment/screens/view_all_overview.dart';

class SkinDisease {
  final String name;
  final double dx;
  final double dy;
  final Color? color;
  final String? description;
  SkinDisease({
    required this.name,
    required this.dx,
    required this.dy,
    this.color,
    this.description,
  });
}

class FaceViewPage extends StatefulWidget {
  @override
  State<FaceViewPage> createState() => _FaceViewPageState();
}

class _FaceViewPageState extends State<FaceViewPage> {
  int _selectedTab = 0; // 0 = All, 1 = Papules, 2 = Acne, etc.
  int _selectedDisease = 0;

  final List<SkinDisease> _diseases = [
    SkinDisease(
      name: "Dead skin cells",
      dx: 0.16,
      dy: 0.93,
      color: Colors.white,
      description: "Dead skin cells can accumulate and cause dullness.",
    ),
    SkinDisease(
      name: "Papules",
      dx: 0.12,
      dy: 0.32,
      color: Colors.purple,
      description: "Papules are small red bumps on the skin.",
    ),
    SkinDisease(
      name: "Acne",
      dx: 0.85,
      dy: 0.25,
      color: Colors.pink,
      description: "Acne occurs when hair follicles become clogged.",
    ),
    SkinDisease(
      name: "Cyst",
      dx: 0.82,
      dy: 0.5,
      color: Colors.orange,
      description: "Cysts are deeper, pus-filled lesions.",
    ),
    // Add more diseases as needed
  ];

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

  @override
  Widget build(BuildContext context) {
    List<Widget> faceDiseasePoints(double width, double height) {
      if (_selectedTab == 0) {
        // All
        return _diseases.asMap().entries.map((entry) {
          final idx = entry.key;
          final d = entry.value;
          return Positioned(
            left: d.dx * width - 18,
            top: d.dy * height - 18,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = idx + 1;
                  _selectedDisease = idx;
                });
              },
              child: _DiseasePoint(
                disease: d,
                highlighted: false,
              ),
            ),
          );
        }).toList();
      } else {
        // Only selected disease
        final d = _diseases[_selectedDisease];
        return [
          Positioned(
            left: d.dx * width - 18,
            top: d.dy * height - 18,
            child: _DiseasePoint(disease: d, highlighted: true),
          ),
          Positioned(
            left: d.dx * width - 18,
            top: d.dy * height + 26,
            child: Text(
              d.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                shadows: [Shadow(blurRadius: 5, color: Colors.black)],
              ),
            ),
          ),
        ];
      }
    }

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
                // Face image with all/selected disease points
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
                          ...faceDiseasePoints(width, height),
                        ],
                      );
                    },
                  ),
                ),
                // Top bar (optional)
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
                // Horizontal tab bar and bottom info/bottom sheet
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.only(top: 16, bottom: 18),
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
                          // Horizontal tab bar: "All", then each disease
                          SizedBox(
                            height: 46,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 7),
                                  child: ChoiceChip(
                                    label: const Text(
                                      "All",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    selected: _selectedTab == 0,
                                    onSelected: (_) {
                                      setState(() => _selectedTab = 0);
                                    },
                                    selectedColor: const Color(0xFF7C6CC6),
                                    backgroundColor: Colors.grey[200],
                                    labelStyle: TextStyle(
                                      color: _selectedTab == 0
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                ),
                                ..._diseases.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final d = entry.value;
                                  final selected = _selectedTab == idx + 1;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 7),
                                    child: ChoiceChip(
                                      label: Text(
                                        d.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      selected: selected,
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedTab = idx + 1;
                                          _selectedDisease = idx;
                                        });
                                      },
                                      selectedColor: d.color ?? const Color(0xFF7C6CC6),
                                      backgroundColor: Colors.grey[200],
                                      labelStyle: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          // Show info for selected disease ONLY if not "All"
                          if (_selectedTab != 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _diseases[_selectedDisease].name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: _diseases[_selectedDisease].color ??
                                          const Color(0xFF7C6CC6),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _diseases[_selectedDisease].description ?? '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          // View All Overview Button (always at bottom)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: SizedBox(
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
                                // onPressed: _showOverviewSheet,
                                onPressed: (){
                                  // Navigator.pushNamed(context, '/view_all_overview');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>  SkinOverviewPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "View All Overview & Skin Analysis",
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Widget to draw a colored point for disease
class _DiseasePoint extends StatelessWidget {
  final SkinDisease disease;
  final bool highlighted;
  const _DiseasePoint({
    required this.disease,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlighted
        ? (disease.color ?? const Color(0xFF7C6CC6))
        : Colors.white;
    final borderColor = highlighted
        ? (disease.color ?? const Color(0xFF7C6CC6))
        : Colors.deepPurple;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: highlighted ? 36 : 28,
      height: highlighted ? 36 : 28,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(100),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Center(
        child: Text(
          disease.name[0],
          style: TextStyle(
            color: highlighted ? Colors.white : Colors.deepPurple,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}