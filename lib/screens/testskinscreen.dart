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
import 'package:http_parser/http_parser.dart';
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
  bool _getSkinPoint = false;
  bool _uploadToServer = false;
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
      backgroundColor: (_imageProvider == null) ? Colors.white : Colors.black,
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
            if (_loading)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 18),
                      Text(
                        (_removingBg == false)
                            ? "Removing background..."
                            : (_getSkinPoint == false)
                                ? " Getting skin points..."
                                : "Almost done...",
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
    // if (_removingBg ) {
    //   return const SizedBox.shrink();
    // }
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
                child: CameraPreview(_cameraController!),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
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
    print("process started");
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
      _removingBg = false;
      _showScanning = false;
    });

    if (picked.path.isNotEmpty) {
      await _getBlackBgFace(File(picked.path));
    }
    print("get black bg face done");

    setState(() {
      _removingBg = true;
      _getSkinPoint = false;
      _uploadToServer = false;
      // _loading = false;
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
    print("analysis done");
  }

  Future<void> _getBlackBgFace(File imageFile) async {
    try {
      // final uri = Uri.parse("http://192.168.1.110:5000/black-bg-face");
      final uri = Uri.parse("http://192.168.1.15:5000/black-bg-face");
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
    print("analyze started");

    try {
      final uri = Uri.parse("http://192.168.1.20:8000/predict");
      final req = http.MultipartRequest('POST', uri);

      String filename;
      String mimeType;
      Uint8List bytesToSend;

      if (kIsWeb && _webImageBytes != null) {
        filename = _webImageName ?? "image.jpg";
        if (filename.isEmpty) filename = "image.jpg";
        String ext = filename.split('.').length > 1
            ? filename.split('.').last.toLowerCase()
            : "jpg";
        mimeType = "image/jpeg";
        if (ext == "png") mimeType = "image/png";
        if (ext == "webp") mimeType = "image/webp";
        if (ext == "gif") mimeType = "image/gif";
        if (!filename.contains('.')) filename = "image.jpg";
        bytesToSend = _webImageBytes!;
      } else {
        filename = picked.name.isNotEmpty ? picked.name : "image.jpg";
        String ext = filename.split('.').length > 1
            ? filename.split('.').last.toLowerCase()
            : "jpg";
        mimeType = "image/jpeg";
        if (ext == "png") mimeType = "image/png";
        if (ext == "webp") mimeType = "image/webp";
        if (ext == "gif") mimeType = "image/gif";
        if (!filename.contains('.')) filename = "image.jpg";
        bytesToSend = previewBytes;
      }

      req.files.add(http.MultipartFile.fromBytes(
        'image',
        bytesToSend,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResp = await req.send();
      final resp = await http.Response.fromStream(streamedResp);

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is Map<String, dynamic>) {
          ailabData = decoded;
        } else if (decoded is List) {
          ailabData = {'results': decoded};
        } else {
          ailabData = null;
        }
      } else {
        ailabData = null;
      }
    } catch (e, st) {
      print('API exception: $e\n$st');
      ailabData = null;
    }
    print("get label analysis done");
    setState(() {
      // _loading = true;
      _error = null;
      _getSkinPoint = true;
      _uploadToServer = false;
      // _scanningImageBytes = previewBytes;
      // _imageProvider = MemoryImage(previewBytes);
    });

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

    // await Future.delayed(const Duration(seconds: 5));
    print("complete upload to server");
    setState(() {
      _analysisJson = ailabData;
      _uploadToServer = true;
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
