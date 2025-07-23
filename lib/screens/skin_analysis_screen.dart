import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:skin_assessment/screens/scan_face_screen.dart';
import '../widgets/skin_analysis_view.dart';
import '../models/skin_analysis_model.dart';
import 'SkinConditionResultPage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class SkinAnalysisScreen extends StatefulWidget {
  const SkinAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<SkinAnalysisScreen> createState() => _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends State<SkinAnalysisScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;
  bool _showCamera = false;
  XFile? _capturedImage;

  ImageProvider? _imageProvider;
  Map<String, dynamic>? _analysisJson;
  Map<String, dynamic>? _gradioResult;
  Uint8List? _webImageBytes;
  String? _webImageName;
  Size? _originalImageSize;
  bool _loading = false;
  String? _error;
  SkinIssueType? _selectedIssueType;
  File? _lastImageFile;
  Uint8List? _lastImageBytes;

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  Uint8List? _scanningImageBytes;

  Uint8List? _blackBgFaceImage;
  bool _removingBg = false;
  bool _showScanning = false;

  @override
  void initState() {
    super.initState();
    _initCameras();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _scanController.repeat();
        }
      });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _initCameras() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final cameras = await availableCameras();
      setState(() {
        _cameras = cameras;
      });
    } catch (e) {
      setState(() {
        _cameras = [];
      });
    }
  }

  Future<void> _startCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;
    _cameraController?.dispose();
    _cameraController = CameraController(
      _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      ),
      ResolutionPreset.high,
      enableAudio: false,
      
    );
    _initializeControllerFuture = _cameraController!.initialize();
    setState(() {
      _showCamera = true;
    });
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    final image = await _cameraController!.takePicture();
    setState(() {
      _capturedImage = image;
      _showCamera = false;
    });
    await _processPickedImage(image, fromCamera: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(title: const Text("Skin Analysis")),
      // bottomNavigationBar: _analysisJson != null
      //     ? Container(
      //       height: 100,
      //       padding:EdgeInsets.all(8),
      //         alignment: Alignment.bottomCenter,
      //         child: Column(
      //           mainAxisSize: MainAxisSize.min,
      //           children: [
      //             // _buildHorizontalIssues(_analysisJson!),
      //             if (_gradioResult != null)
      //               Padding(
      //                 padding: const EdgeInsets.symmetric(
      //                     vertical: 8.0, horizontal: 16),
      //                 child: SizedBox(
      //                   width: double.infinity,
      //                   child: ElevatedButton.icon(
      //                     icon: const Icon(Icons.analytics),
      //                     label: const Text("View Percentage & Summary"),
      //                     onPressed: () {
      //                       Navigator.push(
      //                         context,
      //                         MaterialPageRoute(
      //                           builder: (context) => SkinConditionResultPage(
      //                             gradioResult: _gradioResult!,
      //                             patchJson: _analysisJson,
      //                           ),
      //                         ),
      //                       );
      //                     },
      //                   ),
      //                 ),
      //               ),
      //           ],
      //         ),
      //       )
      //     : SizedBox(
      //         height: 0,
      //       ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _showCamera
                      ? _buildCameraOverlay(context)
                      : _buildImageArea(context),
                ),
                // if (_blackBgFaceImage == null)
                // ScanFaceScreen(
                //   onCameraPressed: _startCamera,
                //   onGalleryPressed: () => _pickImage(ImageSource.gallery),
                // ),
                // Container(
                //   color: Colors.transparent,
                //   padding: const EdgeInsets.only(bottom: 20, top: 8),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       _buildBottomButton(
                //         icon: Icons.camera_alt,
                //         label: "Camera",
                //         onTap: _cameras == null
                //             ? null
                //             : () async {
                //                 await _startCamera();
                //               },
                //       ),
                //       const SizedBox(width: 24),
                //       _buildBottomButton(
                //         icon: Icons.photo_library,
                //         label: "Gallery",
                //         onTap: () => _pickImage(ImageSource.gallery),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
            if (_loading &&
                _scanningImageBytes != null &&
                _originalImageSize != null)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Center(
                          child: Image.memory(
                            _scanningImageBytes!,
                            fit: BoxFit.contain,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _scanController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter:
                                  ScanningLinePainter(_scanAnimation.value),
                              size: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (_removingBg)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 18),
                      Text(
                        "Removing background...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(
      {required IconData icon, required String label, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blueGrey.shade100, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.blueGrey, size: 22),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea(BuildContext context) {
    if (_removingBg) {
      return const SizedBox.shrink();
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_blackBgFaceImage != null && _originalImageSize != null) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.memory(_blackBgFaceImage!, fit: BoxFit.contain),
          ),
          if (_showScanning)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ScanningLinePainter(_scanAnimation.value),
                    size: MediaQuery.of(context).size,
                  );
                },
              ),
            ),
          if (_analysisJson != null)
            Positioned.fill(
              child: SkinAnalysisView(
                analysisJson: _analysisJson!,
                inputImage: MemoryImage(_blackBgFaceImage!),
                originalImageSize: _originalImageSize!,
                selectedType: _selectedIssueType,
                gradioResult: _gradioResult,
              ),
            ),
        ],
      );
    }
    return Container(
      // height: 100,
      child: ScanFaceScreen(
        onCameraPressed: _startCamera,
        onGalleryPressed: _pickImage,
      ),
    );
  }

  Widget _buildCameraOverlay(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _cameraController != null) {
          return Stack(
            children: [
              Center(
                child: CameraPreview(_cameraController!
                
                ),
              ),
              CustomPaint(
                painter: OverlayPainter(),
                child: Container(),
                ),
                // Top fade with instruction text
                Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
                  decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.0),
                    ],
                  ),
                  ),
                  child: const Text(
                  'Set your face in the center of the circle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  ),
                ),
                ),
                // Bottom fade with button
                Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
                  decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.0),
                    ],
                  ),
                  ),
                  child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    ),
                    onPressed: _captureAndAnalyze,
                    child: const Text(
                    'Capture & Analyze',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ),
                ),
                ),
              // Positioned(
              //   left: 20,
              //   top: 20,
              //   child: IconButton(
              //     icon: const Icon(Icons.close, color: Colors.white, size: 36),
              //     onPressed: () {
              //       setState(() => _showCamera = false);
              //     },
              //   ),
              // ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildHorizontalIssues(Map<String, dynamic> analysisJson) {
    final patches = SkinPatch.fromJsonAll(analysisJson);
    final foundTypes = patches
        .where((p) =>
            p.issueType != SkinIssueType.unknown &&
            (p.rect != null || (p.polygon != null && p.polygon!.isNotEmpty)))
        .map((p) => p.issueType)
        .toSet()
        .toList();

    return Container(
      height: 54,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: foundTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, idx) {
          final type = foundTypes[idx];
          final name = skinIssueTypeDisplayName(type);
          final selected = _selectedIssueType == type;
          return ChoiceChip(
            label: Text(name),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedIssueType = selected ? null : type;
              });
            },
            selectedColor: Colors.blue.shade100,
            labelStyle: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.blue : Colors.black,
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      await _processPickedImage(picked, fromCamera: false);
    }
  }

  Future<Uint8List> fixImageOrientation(Uint8List bytes) async {
    final original = img.decodeImage(bytes);
    if (original == null) return bytes;
    final fixed = img.bakeOrientation(original);
    return Uint8List.fromList(img.encodeJpg(fixed));
  }

  Future<void> _processPickedImage(XFile picked,
      {bool fromCamera = false}) async {
    Uint8List? bytes;
    Size? size;

    if (kIsWeb) {
      bytes = await picked.readAsBytes();
      size = await _getImageSizeWeb(bytes);
    } else {
      bytes = await File(picked.path).readAsBytes();
      bytes = await fixImageOrientation(bytes);
      if (_cameraController != null &&
          _cameraController!.description.lensDirection ==
              CameraLensDirection.front) {
        final img.Image? oriented = img.decodeImage(bytes);
        if (oriented != null) {
          final img.Image flipped = img.flipHorizontal(oriented);
          bytes = Uint8List.fromList(img.encodeJpg(flipped));
        }
      }
      size = await _getImageSizeMobileBytes(bytes);
    }

    setState(() {
      _scanningImageBytes = bytes;
      _originalImageSize = size;
      _analysisJson = null;
      _gradioResult = null;
      _loading = true;
      _imageProvider = null;
      _blackBgFaceImage = null;
      _removingBg = true;
      _showScanning = false;
    });

    if (picked.path.isNotEmpty) {
      await _getBlackBgFace(File(picked.path));
    }

    setState(() {
      _removingBg = false;
      _loading = false;
      _showScanning = true;
      _imageProvider =
          _blackBgFaceImage != null ? MemoryImage(_blackBgFaceImage!) : null;
    });

    _scanController.reset();
    _scanController.repeat();

    if (_blackBgFaceImage != null) {
      await _analyzeImage(picked, _blackBgFaceImage!);
    } else {
      await _analyzeImage(picked, bytes);
    }
    _scanController.reset();
    setState(() {
      _showScanning = false;
    });
  }

  Future<void> _getBlackBgFace(File imageFile) async {
    try {
      final uri = Uri.parse("http://192.168.1.110:5000/black-bg-face");
      final request = http.MultipartRequest("POST", uri);
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final decodedImage = await decodeImageFromList(bytes);
        setState(() {
          _blackBgFaceImage = bytes;
          _originalImageSize = Size(
              decodedImage.width.toDouble(), decodedImage.height.toDouble());
        });
      } else {
        print('Error from face crop API: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to connect to face crop API: $e');
    }
  }

  Future<Size> _getImageSizeMobileBytes(Uint8List bytes) async {
    final decodedImage = await decodeImageFromList(bytes);
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }

  Future<Size> _getImageSizeWeb(Uint8List bytes) async {
    final decodedImage = await decodeImageFromList(bytes);
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }

  Future<void> _analyzeImage(XFile picked, Uint8List previewBytes) async {
    Map<String, dynamic>? ailabData;
    Map<String, dynamic>? uploadApiResult;

    final hardcodedJson = {
      "error_code": 0,
      "error_detail": {
        "status_code": 200,
        "code": "",
        "code_message": "",
        "message": ""
      },
      "face_rectangle": {
        "top": 2096,
        "left": 1034,
        "width": 1377,
        "height": 1377
      },
      "log_id": "75751238",
      "request_id": "1752893780,45690f27-2f06-4359-9a97-f8720e741e0f",
      "result": {
        "skin_age": {"value": 32},
        "eye_pouch": {"value": 1, "confidence": 0.91235083},
        "eye_pouch_severity": {"value": 1, "confidence": 0.7655218},
        "dark_circle": {"value": 1, "confidence": 1},
        "dark_circle_severity": {"value": 2, "confidence": 1},
        "forehead_wrinkle": {"value": 0, "confidence": 0.5229976},
        "crows_feet": {"value": 0, "confidence": 0.74089074},
        "eye_finelines": {"value": 1, "confidence": 0.998478},
        "eye_finelines_severity": {"value": 2, "confidence": 0.64239377},
        "glabella_wrinkle": {"value": 0, "confidence": 0.90312356},
        "nasolabial_fold": {"value": 1, "confidence": 0.74611866},
        "nasolabial_fold_severity": {"value": 0, "confidence": 0.3370819},
        "skin_type": {
          "skin_type": 3,
          "details": [
            {"value": 0, "confidence": 0.031774573},
            {"value": 0, "confidence": 0.0071086767},
            {"value": 0, "confidence": 0.027827105},
            {"value": 1, "confidence": 0.93328965}
          ]
        },
        "pores_forehead": {"value": 3, "confidence": 1},
        "pores_left_cheek": {"value": 2, "confidence": 1},
        "pores_right_cheek": {"value": 1, "confidence": 1},
        "pores_jaw": {"value": 1, "confidence": 1},
        "blackhead": {"value": 0, "confidence": 1},
        "skintone_ita": {"ITA": 25.435968, "skintone": 3},
        "skin_hue_ha": {"HA": 47.95129, "skin_hue": 2},
        "acne": {
          "rectangle": [
            {"left": 1234, "top": 2038, "width": 25, "height": 39}
          ],
          "confidence": [0.41853112],
          "polygon": [
            [
              {"x": 1255, "y": 2076},
              {"x": 1250, "y": 2076},
              {"x": 1239, "y": 2064},
              {"x": 1243, "y": 2045},
              {"x": 1250, "y": 2039},
              {"x": 1258, "y": 2040},
              {"x": 1258, "y": 2070}
            ]
          ],
          "count": 1
        },
        "mole": {"rectangle": [], "confidence": [], "polygon": [], "count": 0},
        "brown_spot": {
          "rectangle": [
            {"left": 2028, "top": 2549, "width": 14, "height": 16},
            {"left": 1469, "top": 1747, "width": 21, "height": 24},
            {"left": 1699, "top": 2535, "width": 20, "height": 23},
            {"left": 2243, "top": 2516, "width": 15, "height": 23},
            {"left": 2087, "top": 2855, "width": 17, "height": 15},
            {"left": 2094, "top": 2828, "width": 36, "height": 27},
            {"left": 2206, "top": 2524, "width": 18, "height": 20},
            {"left": 1225, "top": 2353, "width": 17, "height": 20},
            {"left": 1780, "top": 2757, "width": 30, "height": 26},
            {"left": 1105, "top": 2251, "width": 14, "height": 16},
            {"left": 1074, "top": 2106, "width": 10, "height": 15},
            {"left": 1562, "top": 1723, "width": 23, "height": 22},
            {"left": 1233, "top": 1884, "width": 23, "height": 24},
            {"left": 1249, "top": 2860, "width": 14, "height": 17},
            {"left": 2240, "top": 2752, "width": 24, "height": 18},
            {"left": 1873, "top": 1799, "width": 31, "height": 26},
            {"left": 1288, "top": 1976, "width": 18, "height": 17},
            {"left": 1987, "top": 2541, "width": 16, "height": 14},
            {"left": 1231, "top": 2830, "width": 24, "height": 21},
            {"left": 2185, "top": 1895, "width": 26, "height": 27},
            {"left": 1217, "top": 2422, "width": 16, "height": 17},
            {"left": 1132, "top": 2209, "width": 27, "height": 36},
            {"left": 2245, "top": 2355, "width": 24, "height": 22},
            {"left": 1259, "top": 2838, "width": 18, "height": 18},
            {"left": 1954, "top": 3225, "width": 15, "height": 17},
            {"left": 1958, "top": 2547, "width": 25, "height": 24},
            {"left": 2251, "top": 2673, "width": 19, "height": 15},
            {"left": 2298, "top": 2542, "width": 15, "height": 24}
          ],
          "confidence": [
            0.6591537,
            0.6564733,
            0.5293909,
            0.45167825,
            0.44775632,
            0.43221065,
            0.42005286,
            0.38631523,
            0.36975664,
            0.36869064,
            0.36506918,
            0.36434415,
            0.36414403,
            0.36112016,
            0.36015072,
            0.3584788,
            0.3565095,
            0.34003255,
            0.33215356,
            0.33033478,
            0.327734,
            0.32283723,
            0.3175973,
            0.3138148,
            0.30364007,
            0.3012858,
            0.30043206,
            0.3002352
          ],
          "polygon": [
            [
              {"x": 2037, "y": 2562},
              {"x": 2030, "y": 2559},
              {"x": 2032, "y": 2551},
              {"x": 2039, "y": 2555}
            ],
            [
              {"x": 1489, "y": 1767},
              {"x": 1482, "y": 1770},
              {"x": 1474, "y": 1767},
              {"x": 1469, "y": 1756},
              {"x": 1482, "y": 1750},
              {"x": 1487, "y": 1752}
            ],
            [
              {"x": 1715, "y": 2553},
              {"x": 1704, "y": 2554},
              {"x": 1699, "y": 2541},
              {"x": 1710, "y": 2537},
              {"x": 1715, "y": 2546}
            ],
            [
              {"x": 2257, "y": 2519},
              {"x": 2251, "y": 2537},
              {"x": 2245, "y": 2537},
              {"x": 2243, "y": 2533},
              {"x": 2246, "y": 2518}
            ],
            [
              {"x": 2103, "y": 2868},
              {"x": 2087, "y": 2864},
              {"x": 2087, "y": 2855},
              {"x": 2102, "y": 2862}
            ],
            [
              {"x": 2127, "y": 2832},
              {"x": 2128, "y": 2841},
              {"x": 2111, "y": 2854},
              {"x": 2102, "y": 2854},
              {"x": 2094, "y": 2845},
              {"x": 2095, "y": 2835},
              {"x": 2110, "y": 2828},
              {"x": 2124, "y": 2829}
            ],
            [
              {"x": 2223, "y": 2539},
              {"x": 2210, "y": 2543},
              {"x": 2207, "y": 2524},
              {"x": 2219, "y": 2524}
            ],
            [
              {"x": 1239, "y": 2354},
              {"x": 1235, "y": 2367},
              {"x": 1225, "y": 2369},
              {"x": 1227, "y": 2354}
            ],
            [
              {"x": 1806, "y": 2770},
              {"x": 1803, "y": 2781},
              {"x": 1780, "y": 2781},
              {"x": 1780, "y": 2771},
              {"x": 1791, "y": 2761},
              {"x": 1797, "y": 2762}
            ],
            [
              {"x": 1118, "y": 2254},
              {"x": 1118, "y": 2259},
              {"x": 1109, "y": 2265},
              {"x": 1105, "y": 2261},
              {"x": 1111, "y": 2251}
            ],
            [
              {"x": 1081, "y": 2106},
              {"x": 1083, "y": 2111},
              {"x": 1077, "y": 2118},
              {"x": 1075, "y": 2115}
            ],
            [
              {"x": 1584, "y": 1742},
              {"x": 1566, "y": 1744},
              {"x": 1563, "y": 1739},
              {"x": 1577, "y": 1736}
            ],
            [
              {"x": 1255, "y": 1907},
              {"x": 1246, "y": 1907},
              {"x": 1233, "y": 1900},
              {"x": 1233, "y": 1895},
              {"x": 1242, "y": 1886},
              {"x": 1251, "y": 1887}
            ],
            [
              {"x": 1258, "y": 2860},
              {"x": 1258, "y": 2874},
              {"x": 1253, "y": 2875},
              {"x": 1252, "y": 2868}
            ],
            [
              {"x": 2260, "y": 2763},
              {"x": 2249, "y": 2766},
              {"x": 2240, "y": 2759},
              {"x": 2246, "y": 2755},
              {"x": 2260, "y": 2756}
            ],
            [
              {"x": 1903, "y": 1811},
              {"x": 1895, "y": 1817},
              {"x": 1878, "y": 1815},
              {"x": 1873, "y": 1803},
              {"x": 1885, "y": 1799},
              {"x": 1902, "y": 1805}
            ],
            [
              {"x": 1305, "y": 1977},
              {"x": 1305, "y": 1987},
              {"x": 1298, "y": 1992},
              {"x": 1288, "y": 1992},
              {"x": 1294, "y": 1976}
            ],
            [
              {"x": 2002, "y": 2550},
              {"x": 1989, "y": 2551},
              {"x": 1987, "y": 2544},
              {"x": 2000, "y": 2545}
            ],
            [
              {"x": 1253, "y": 2832},
              {"x": 1253, "y": 2836},
              {"x": 1239, "y": 2849},
              {"x": 1233, "y": 2847},
              {"x": 1232, "y": 2843},
              {"x": 1241, "y": 2833},
              {"x": 1250, "y": 2830}
            ],
            [
              {"x": 2206, "y": 1919},
              {"x": 2189, "y": 1915},
              {"x": 2185, "y": 1909},
              {"x": 2185, "y": 1901},
              {"x": 2200, "y": 1900},
              {"x": 2207, "y": 1904}
            ],
            [
              {"x": 1232, "y": 2422},
              {"x": 1229, "y": 2436},
              {"x": 1222, "y": 2435},
              {"x": 1219, "y": 2427},
              {"x": 1226, "y": 2422}
            ],
            [
              {"x": 1153, "y": 2242},
              {"x": 1132, "y": 2244},
              {"x": 1137, "y": 2218},
              {"x": 1158, "y": 2212},
              {"x": 1158, "y": 2237}
            ],
            [
              {"x": 2265, "y": 2360},
              {"x": 2263, "y": 2367},
              {"x": 2253, "y": 2376},
              {"x": 2245, "y": 2376},
              {"x": 2245, "y": 2355},
              {"x": 2259, "y": 2355}
            ],
            [
              {"x": 1273, "y": 2842},
              {"x": 1267, "y": 2854},
              {"x": 1259, "y": 2852},
              {"x": 1263, "y": 2840}
            ],
            [
              {"x": 1967, "y": 3237},
              {"x": 1955, "y": 3236},
              {"x": 1955, "y": 3225},
              {"x": 1962, "y": 3225}
            ],
            [
              {"x": 1979, "y": 2570},
              {"x": 1971, "y": 2570},
              {"x": 1958, "y": 2564},
              {"x": 1958, "y": 2551},
              {"x": 1962, "y": 2547},
              {"x": 1978, "y": 2553}
            ],
            [
              {"x": 2269, "y": 2674},
              {"x": 2263, "y": 2685},
              {"x": 2254, "y": 2684},
              {"x": 2254, "y": 2677}
            ],
            [
              {"x": 2306, "y": 2565},
              {"x": 2298, "y": 2565},
              {"x": 2302, "y": 2543},
              {"x": 2309, "y": 2548},
              {"x": 2311, "y": 2558}
            ]
          ],
          "count": 28
        },
        "closed_comedones": {
          "rectangle": [
            {"left": 1377, "top": 1894, "width": 19, "height": 19},
            {"left": 2060, "top": 2594, "width": 17, "height": 16},
            {"left": 2233, "top": 2592, "width": 18, "height": 20}
          ],
          "confidence": [0.3517206, 0.32005703, 0.31907234],
          "polygon": [
            [
              {"x": 1387, "y": 1894},
              {"x": 1389, "y": 1902},
              {"x": 1384, "y": 1912},
              {"x": 1377, "y": 1912},
              {"x": 1377, "y": 1902},
              {"x": 1381, "y": 1894}
            ],
            [
              {"x": 2076, "y": 2594},
              {"x": 2076, "y": 2609},
              {"x": 2062, "y": 2609},
              {"x": 2061, "y": 2607}
            ],
            [
              {"x": 2246, "y": 2593},
              {"x": 2250, "y": 2600},
              {"x": 2247, "y": 2609},
              {"x": 2233, "y": 2611},
              {"x": 2233, "y": 2604}
            ]
          ],
          "count": 3
        },
        "acne_mark": {
          "rectangle": [],
          "confidence": [],
          "polygon": [],
          "count": 0
        },
        "acne_nodule": {
          "rectangle": [],
          "confidence": [],
          "polygon": [],
          "count": 0
        },
        "acne_pustule": {
          "rectangle": [],
          "confidence": [],
          "polygon": [],
          "count": 0
        },
        "blackhead_count": 32,
        "skintone": {"value": 2, "confidence": 0.58637375},
        "fine_line": {
          "forehead_count": 0,
          "left_undereye_count": 0,
          "right_undereye_count": 0,
          "left_cheek_count": 0,
          "right_cheek_count": 0,
          "left_crowsfeet_count": 0,
          "right_crowsfeet_count": 0,
          "glabella_count": 0
        },
        "wrinkle_count": {
          "forehead_count": 0,
          "left_undereye_count": 0,
          "right_undereye_count": 0,
          "left_mouth_count": 0,
          "right_mouth_count": 0,
          "left_nasolabial_count": 1,
          "right_nasolabial_count": 1,
          "glabella_count": 0,
          "left_cheek_count": 0,
          "right_cheek_count": 0,
          "left_crowsfeet_count": 0,
          "right_crowsfeet_count": 0
        },
        "oily_intensity": {
          "t_zone": {"area": 0.31, "intensity": 2},
          "left_cheek": {"area": 0.24, "intensity": 1},
          "right_cheek": {"area": 0.25, "intensity": 1},
          "chin_area": {"area": 0, "intensity": 0},
          "full_face": {"area": 0.25, "intensity": 1}
        },
        "enlarged_pore_count": {
          "forehead_count": 566,
          "left_cheek_count": 209,
          "right_cheek_count": 78,
          "chin_count": 130
        },
        "right_dark_circle_rete": {"value": 2},
        "left_dark_circle_rete": {"value": 0},
        "right_dark_circle_pigment": {"value": 3},
        "left_dark_circle_pigment": {"value": 3},
        "right_dark_circle_structural": {"value": 1},
        "left_dark_circle_structural": {"value": 2},
        "dark_circle_mark": {
          "left_eye_rect": {
            "left": 1216,
            "top": 2179,
            "width": 416,
            "height": 362
          },
          "right_eye_rect": {
            "left": 1878,
            "top": 2185,
            "width": 408,
            "height": 355
          }
        },
        "water": {
          "water_severity": 37,
          "water_area": 0.304,
          "water_forehead": {"area": 0.336},
          "water_leftcheek": {"area": 0.329},
          "water_rightcheek": {"area": 0.164}
        },
        "rough": {
          "rough_severity": 19,
          "rough_area": 0.374,
          "rough_forehead": {"area": 0.398},
          "rough_leftcheek": {"area": 0.4},
          "rough_rightcheek": {"area": 0.326},
          "rough_jaw": {"area": 0.275}
        },
        "left_mouth_wrinkle_severity": {"value": 0},
        "right_mouth_wrinkle_severity": {"value": 0},
        "forehead_wrinkle_severity": {"value": 0},
        "left_crows_feet_severity": {"value": 0},
        "right_crows_feet_severity": {"value": 0},
        "left_eye_finelines_severity": {"value": 0},
        "right_eye_finelines_severity": {"value": 0},
        "glabella_wrinkle_severity": {"value": 0},
        "left_nasolabial_fold_severity": {"value": 2},
        "right_nasolabial_fold_severity": {"value": 2},
        "left_cheek_wrinkle_severity": {"value": 0},
        "right_cheek_wrinkle_severity": {"value": 0},
        "forehead_wrinkle_info": {
          "wrinkle_score": 0,
          "wrinkle_severity_level": 0,
          "wrinkle_norm_length": 0,
          "wrinkle_norm_depth": 0,
          "wrinkle_pixel_density": 0,
          "wrinkle_area_ratio": 0,
          "wrinkle_deep_ratio": 0,
          "wrinkle_deep_num": 0,
          "wrinkle_shallow_num": 0
        },
        "left_eye_wrinkle_info": {
          "wrinkle_score": 0,
          "wrinkle_severity_level": 0,
          "wrinkle_norm_length": 0,
          "wrinkle_norm_depth": 0,
          "wrinkle_pixel_density": 0,
          "wrinkle_area_ratio": 0,
          "wrinkle_deep_ratio": 0,
          "wrinkle_deep_num": 0,
          "wrinkle_shallow_num": 0
        },
        "right_eye_wrinkle_info": {
          "wrinkle_score": 0,
          "wrinkle_severity_level": 0,
          "wrinkle_norm_length": 0,
          "wrinkle_norm_depth": 0,
          "wrinkle_pixel_density": 0,
          "wrinkle_area_ratio": 0,
          "wrinkle_deep_ratio": 0,
          "wrinkle_deep_num": 0,
          "wrinkle_shallow_num": 0
        },
        "left_crowsfeet_wrinkle_info": {
          "wrinkle_score": 0,
          "wrinkle_severity_level": 0,
          "wrinkle_norm_length": 0,
          "wrinkle_norm_depth": 0,
          "wrinkle_pixel_density": 0,
          "wrinkle_area_ratio": 0,
          "wrinkle_deep_ratio": 0,
          "wrinkle_deep_num": 0,
          "wrinkle_shallow_num": 0
        },
        "right_crowsfeet_wrinkle_info": {
          "wrinkle_score": 0,
          "wrinkle_severity_level": 0,
          "wrinkle_norm_length": 0,
          "wrinkle_norm_depth": 0,
          "wrinkle_pixel_density": 0,
          "wrinkle_area_ratio": 0,
          "wrinkle_deep_ratio": 0,
          "wrinkle_deep_num": 0,
          "wrinkle_shallow_num": 0
        },
        "glabella_wrinkle_info": {
          "wrinkle_score": 0,
          "wrinkle_severity_level": 0,
          "wrinkle_norm_length": 0,
          "wrinkle_norm_depth": 0,
          "wrinkle_pixel_density": 0,
          "wrinkle_area_ratio": 0,
          "wrinkle_deep_ratio": 0,
          "wrinkle_deep_num": 0,
          "wrinkle_shallow_num": 0
        },
        "left_mouth_wrinkle_info": {
          "wrinkle_score": 0,
          "wrinkle_severity_level": 0,
          "wrinkle_norm_length": 0,
          "wrinkle_norm_depth": 0,
          "wrinkle_pixel_density": 0,
          "wrinkle_area_ratio": 0,
          "wrinkle_deep_ratio": 0,
          "wrinkle_deep_num": 0,
          "wrinkle_shallow_num": 0
        },
        "right_mouth_wrinkle_info": {
          "wrinkle_score": 0,
          "wrinkle_severity_level": 0,
          "wrinkle_norm_length": 0,
          "wrinkle_norm_depth": 0,
          "wrinkle_pixel_density": 0,
          "wrinkle_area_ratio": 0,
          "wrinkle_deep_ratio": 0,
          "wrinkle_deep_num": 0,
          "wrinkle_shallow_num": 0
        },
        "left_nasolabial_wrinkle_info": {
          "wrinkle_score": 41,
          "wrinkle_severity_level": 2,
          "wrinkle_norm_length": 0.25368653929129537,
          "wrinkle_norm_depth": 0.40999224548576496,
          "wrinkle_pixel_density": 0.08152018247750788,
          "wrinkle_area_ratio": 0.0514555416199089,
          "wrinkle_deep_ratio": 1,
          "wrinkle_deep_num": 1,
          "wrinkle_shallow_num": 0
        },
        "right_nasolabial_wrinkle_info": {
          "wrinkle_score": 37,
          "wrinkle_severity_level": 2,
          "wrinkle_norm_length": 0.15765830125447733,
          "wrinkle_norm_depth": 0.3671023965141612,
          "wrinkle_pixel_density": 0.05882895762958465,
          "wrinkle_area_ratio": 0.045952782462057334,
          "wrinkle_deep_ratio": 1,
          "wrinkle_deep_num": 1,
          "wrinkle_shallow_num": 0
        },
        "left_cheek_wrinkle_info": {
          "wrinkle_score": 0,
          "wrinkle_severity_level": 0,
          "wrinkle_norm_length": 0,
          "wrinkle_norm_depth": 0,
          "wrinkle_pixel_density": 0,
          "wrinkle_area_ratio": 0,
          "wrinkle_deep_ratio": 0,
          "wrinkle_deep_num": 0,
          "wrinkle_shallow_num": 0
        },
        "right_cheek_wrinkle_info": {
          "wrinkle_score": 0,
          "wrinkle_severity_level": 0,
          "wrinkle_norm_length": 0,
          "wrinkle_norm_depth": 0,
          "wrinkle_pixel_density": 0,
          "wrinkle_area_ratio": 0,
          "wrinkle_deep_ratio": 0,
          "wrinkle_deep_num": 0,
          "wrinkle_shallow_num": 0
        },
        "score_info": {
          "dark_circle_score": 30,
          "skin_type_score": 44,
          "wrinkle_score": 94,
          "oily_intensity_score": 50,
          "pores_score": 65,
          "blackhead_score": 90,
          "acne_score": 93,
          "sensitivity_score": 99,
          "melanin_score": 91,
          "water_score": 63,
          "rough_score": 81,
          "total_score": 75,
          "pores_type_score": {
            "pores_forehead_score": 43,
            "pores_leftcheek_score": 54,
            "pores_rightcheek_score": 83,
            "pores_jaw_score": 79
          },
          "dark_circle_type_score": {
            "left_dark_circle_score": 65,
            "right_dark_circle_score": 58
          }
        },
        "left_eye_pouch_rect": {
          "left": 1216,
          "top": 2179,
          "width": 416,
          "height": 362
        },
        "right_eye_pouch_rect": {
          "left": 1878,
          "top": 2185,
          "width": 408,
          "height": 355
        },
        "melasma": {"value": 1, "confidence": 0.54316527},
        "freckle": {"value": 0, "confidence": 0.45408517},
        "image_quality": {
          "face_rect": {
            "left": 1002,
            "top": 1542,
            "width": 1423,
            "height": 1934
          },
          "face_ratio": 0.14427549,
          "hair_occlusion": 0.01983864,
          "face_orientation": {
            "yaw": 1.734318,
            "pitch": 10.104296,
            "roll": 3.6102178
          },
          "glasses": 0
        },
        "sensitivity_type_v1": 1
      }
    };
    ailabData = hardcodedJson;

    if (!kIsWeb) {
      _lastImageFile = File(picked.path);
      _lastImageBytes = previewBytes;
      if (_lastImageFile != null && _lastImageBytes != null) {
        try {
          final uri = Uri.parse(
              'https://aestheticai.globalspace.in/dev/aesthetic_backend/public/api/v3/uploadImageFromDoc');
          var request = http.MultipartRequest('POST', uri);

          request.fields['doctor_id'] = "70690";
          request.fields['patient_id'] = "42";
          request.fields['patient_number'] = "8600285374";

          request.files.add(
            http.MultipartFile.fromBytes(
              'images[]',
              _lastImageBytes!,
              filename: basename(_lastImageFile!.path),
            ),
          );

          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            final decoded = json.decode(response.body);
            uploadApiResult = decoded;
          }
        } catch (e) {
          uploadApiResult = null;
        }
      }
    }

    setState(() {
      _analysisJson = ailabData;
      _gradioResult = uploadApiResult;
      _loading = false;
      _error = (_analysisJson == null && _gradioResult == null)
          ? "Both APIs failed or returned no detections. Try again."
          : null;
      _imageProvider = MemoryImage(previewBytes);
      _scanningImageBytes = null;
    });
  }
}

class OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ovalWidth = size.width * 0.75;
    final ovalHeight = size.height * 0.50;
    final rect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Draw overlay everywhere except the oval
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);

    // Create a path for the whole area
    final overlayPath = Path()..addRect(Offset.zero & size);

    // Create a path for the oval
    final ovalPath = Path()..addOval(rect);

    // Subtract oval from overlayPath, leaving only the area outside the oval
    final maskPath =
        Path.combine(PathOperation.difference, overlayPath, ovalPath);
    canvas.drawPath(maskPath, overlayPaint);

    // Draw dashed oval border
    final dashPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const dashLength = 12.0;
    const gapLength = 8.0;
    final perimeter = 2 * 3.141592653589793 * ((ovalWidth + ovalHeight) / 4);
    final dashCount = (perimeter / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle =
          (i * (dashLength + gapLength)) / ((ovalWidth + ovalHeight) / 4);
      final endAngle = startAngle + dashLength / ((ovalWidth + ovalHeight) / 4);
      final path = Path();
      path.addArc(rect, startAngle, endAngle - startAngle);
      canvas.drawPath(path, dashPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ScanningLinePainter extends CustomPainter {
  final double progress;

  ScanningLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.green.withOpacity(0.05),
          Colors.green.withOpacity(0.3),
          Colors.green.withOpacity(0.05),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, y - 6, size.width, 12));
    canvas.drawRect(Rect.fromLTWH(0, y - 6, size.width, 12), gradientPaint);
  }

  @override
  bool shouldRepaint(ScanningLinePainter oldDelegate) =>
      progress != oldDelegate.progress;
}
