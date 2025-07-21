import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const Map<String, dynamic> hardcodedJson = {
  "face_rectangle": {"top": 2096, "left": 1034, "width": 1377, "height": 1377},
  "result": {
    "acne": {
      "rectangle": [
        {"left": 1234, "top": 2038, "width": 25, "height": 39}
      ],
      "count": 1
    },
    "brown_spot": {
      "rectangle": [
        {"left": 2028, "top": 2549, "width": 14, "height": 16},
        {"left": 1469, "top": 1747, "width": 21, "height": 24},
        {"left": 1699, "top": 2535, "width": 20, "height": 23},
        {"left": 2243, "top": 2516, "width": 15, "height": 23},
      ],
      "count": 28
    },
    "left_eye_pouch_rect": {
      "left": 1216, "top": 2179, "width": 416, "height": 362
    },
    "right_eye_pouch_rect": {
      "left": 1878, "top": 2185, "width": 408, "height": 355
    }
  }
};

class FaceLabelRect {
  final String label;
  final Rect rect;
  FaceLabelRect(this.label, this.rect);
}

class FaceViewPage extends StatefulWidget {
  const FaceViewPage({Key? key}) : super(key: key);

  @override
  State<FaceViewPage> createState() => _FaceViewPageState();
}

class _FaceViewPageState extends State<FaceViewPage> {
  File? _imageFile;
  Uint8List? _imageBytes;
  late final List<FaceLabelRect> _allRects;
  int? _highlightedIdx;
  Size? _imageSize; // actual picked image size

  static const double analysisImageW = 4000.0;
  static const double analysisImageH = 4000.0;

  @override
  void initState() {
    super.initState();
    _allRects = _parseRectsFromJson(hardcodedJson);
  }

  List<FaceLabelRect> _parseRectsFromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>;
    final List<FaceLabelRect> rects = [];

    final face = json['face_rectangle'];
    if (face != null) {
      rects.add(FaceLabelRect(
        'Face',
        Rect.fromLTWH(
            (face['left'] ?? 0).toDouble(),
            (face['top'] ?? 0).toDouble(),
            (face['width'] ?? 0).toDouble(),
            (face['height'] ?? 0).toDouble()),
      ));
    }

    final acne = result['acne'];
    if (acne != null && acne['rectangle'] != null) {
      for (var i = 0; i < (acne['rectangle'] as List).length; i++) {
        final r = acne['rectangle'][i];
        rects.add(FaceLabelRect(
          'Acne ${i + 1}',
          Rect.fromLTWH(
              (r['left'] ?? 0).toDouble(),
              (r['top'] ?? 0).toDouble(),
              (r['width'] ?? 0).toDouble(),
              (r['height'] ?? 0).toDouble()),
        ));
      }
    }

    final brown = result['brown_spot'];
    if (brown != null && brown['rectangle'] != null) {
      for (var i = 0; i < (brown['rectangle'] as List).length; i++) {
        final r = brown['rectangle'][i];
        rects.add(FaceLabelRect(
          'Brown Spot ${i + 1}',
          Rect.fromLTWH(
              (r['left'] ?? 0).toDouble(),
              (r['top'] ?? 0).toDouble(),
              (r['width'] ?? 0).toDouble(),
              (r['height'] ?? 0).toDouble()),
        ));
      }
    }

    final leftEye = result['left_eye_pouch_rect'];
    if (leftEye != null) {
      rects.add(FaceLabelRect(
        'Left Eye Pouch',
        Rect.fromLTWH(
            (leftEye['left'] ?? 0).toDouble(),
            (leftEye['top'] ?? 0).toDouble(),
            (leftEye['width'] ?? 0).toDouble(),
            (leftEye['height'] ?? 0).toDouble()),
      ));
    }
    final rightEye = result['right_eye_pouch_rect'];
    if (rightEye != null) {
      rects.add(FaceLabelRect(
        'Right Eye Pouch',
        Rect.fromLTWH(
            (rightEye['left'] ?? 0).toDouble(),
            (rightEye['top'] ?? 0).toDouble(),
            (rightEye['width'] ?? 0).toDouble(),
            (rightEye['height'] ?? 0).toDouble()),
      ));
    }
    return rects;
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageBytes = bytes;
        _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        _highlightedIdx = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f6),
      body: SafeArea(
        child: _imageFile == null
            ? _buildInitialPick(context)
            : _buildImageWithOverlay(context),
      ),
    );
  }

  Widget _buildInitialPick(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 96, color: Colors.deepPurple),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff7c6cc6),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _pickImageFromCamera,
            child: const Text(
              "Scan now!",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWithOverlay(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dispW = constraints.maxWidth;
        final dispH = constraints.maxHeight;
        if (_imageBytes == null || _imageSize == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final imageW = _imageSize!.width;
        final imageH = _imageSize!.height;

        final scale = (dispW / imageW < dispH / imageH)
            ? dispW / imageW
            : dispH / imageH;
        final renderW = imageW * scale;
        final renderH = imageH * scale;
        final dx = (dispW - renderW) / 2;
        final dy = (dispH - renderH) / 2;

        return Stack(
          children: [
            // Image
            Positioned(
              left: dx,
              top: dy,
              width: renderW,
              height: renderH,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.fill,
                  width: renderW,
                  height: renderH,
                ),
              ),
            ),
            // Overlay all rects
            ..._allRects.asMap().entries.map((entry) {
              final idx = entry.key;
              final rect = entry.value.rect;
              final isHighlighted = _highlightedIdx == idx;
              final scaledRect = Rect.fromLTWH(
                rect.left * scale + dx,
                rect.top * scale + dy,
                rect.width * scale,
                rect.height * scale,
              );
              return Positioned(
                left: scaledRect.left,
                top: scaledRect.top,
                width: scaledRect.width,
                height: scaledRect.height,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _highlightedIdx = idx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isHighlighted ? Colors.purple : Colors.red,
                        width: isHighlighted ? 4 : 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isHighlighted
                          ? Colors.purple.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          entry.value.label,
                          style: TextStyle(
                              color: isHighlighted
                                  ? Colors.purple
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              shadows: [
                                Shadow(
                                    blurRadius: 3,
                                    color: Colors.white70,
                                    offset: Offset(1, 1))
                              ]),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            // Back button
            Positioned(
              left: 16,
              top: 36,
              child: ClipOval(
                child: Material(
                  color: Colors.white.withOpacity(0.8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
                    onPressed: () => setState(() {
                      _imageFile = null;
                      _imageBytes = null;
                      _imageSize = null;
                      _highlightedIdx = null;
                    }),
                  ),
                ),
              ),
            ),
            // Draggable Bottom Sheet
            if (_highlightedIdx != null)
              _draggableInfoSheet(context, _allRects[_highlightedIdx!], scale, dx, dy, renderW, renderH),
            // Label bar (always visible, on bottom)
            Align(
              alignment: Alignment.bottomCenter,
              child: _allLabelsPanel(context),
            ),
          ],
        );
      },
    );
  }

  // Horizontal label bar
  Widget _allLabelsPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 100,
        minHeight: 60,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ]
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_allRects.length, (idx) {
            final label = _allRects[idx].label;
            final isHighlighted = _highlightedIdx == idx;
            return GestureDetector(
              onTap: () {
                setState(() => _highlightedIdx = idx);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.purple.withOpacity(0.15) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHighlighted ? Colors.purple : Colors.deepPurple[100]!,
                    width: isHighlighted ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isHighlighted)
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            isHighlighted ? Colors.purple : Colors.deepPurple[100],
                        child: Text(
                          (idx + 1).toString(),
                          style: TextStyle(
                              color: isHighlighted ? Colors.white : Colors.purple,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (!isHighlighted) const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                          color: isHighlighted ? Colors.purple : Colors.black87,
                          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Draggable bottom sheet with zoomed image & info
  Widget _draggableInfoSheet(
    BuildContext context,
    FaceLabelRect rectLabel,
    double scale,
    double dx,
    double dy,
    double renderW,
    double renderH,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.22,
      minChildSize: 0.18,
      maxChildSize: 0.6,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // --- Zoomed crop image of selected region ---
                if (_imageBytes != null)
                  _zoomedCropWidget(rectLabel.rect),
                const SizedBox(height: 12),
                Text(
                  rectLabel.label,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple),
                ),
                const SizedBox(height: 8),
                // Add info here based on label
                _infoContent(rectLabel.label),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget to show the cropped image region (zoomed)
  Widget _zoomedCropWidget(Rect region) {
    if (_imageBytes == null || _imageSize == null) return const SizedBox();
    // Use AspectRatio to avoid distortion, show a square window
    return Container(
      width: 120,
      height: 120,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.purple.withOpacity(0.12),
              blurRadius: 12,
              spreadRadius: 2)
        ],
      ),
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: region.width,
          height: region.height,
          child: OverflowBox(
            minWidth: _imageSize!.width,
            minHeight: _imageSize!.height,
            maxWidth: _imageSize!.width,
            maxHeight: _imageSize!.height,
            child: Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
              alignment: Alignment.topLeft,
              // The key trick: shift using Transform to show region
              // This crops to the region
              colorBlendMode: BlendMode.srcOver,
              color: Colors.transparent,
              // Use Transform to offset the image so the region is at (0,0)
              // This works because the parent SizedBox is the region size.
            ),
          ),
        ),
      ),
    );
  }

  // Info content for the selected label
  Widget _infoContent(String label) {
    // You can expand this map for more details per disease/feature
    const infoMap = {
      'Face': 'The detected face region.',
      'Acne 1': 'Acne: Small inflamed bump on the skin, usually red.',
      'Brown Spot 1': 'Brown Spot: Hyperpigmentation, harmless but can be a sign of sun exposure.',
      'Brown Spot 2': 'Brown Spot: Hyperpigmentation, harmless but can be a sign of sun exposure.',
      'Brown Spot 3': 'Brown Spot: Hyperpigmentation, harmless but can be a sign of sun exposure.',
      'Brown Spot 4': 'Brown Spot: Hyperpigmentation, harmless but can be a sign of sun exposure.',
      'Left Eye Pouch': 'Under-eye puffiness, often due to aging or fatigue.',
      'Right Eye Pouch': 'Under-eye puffiness, often due to aging or fatigue.',
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        infoMap[label] ??
            'No additional information about this region.',
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        textAlign: TextAlign.left,
      ),
    );
  }
}