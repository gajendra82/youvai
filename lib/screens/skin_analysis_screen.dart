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
import 'dart:html' as html;

// Helper class to return bytes and size together
class ZoomResult {
  final Uint8List bytes;
  final Size size;
  ZoomResult(this.bytes, this.size);
}

class SkinAnalysisScreen extends StatefulWidget {
  final Uint8List? initialImageBytes;
  final Size? initialImageSize;

  const SkinAnalysisScreen({
    Key? key,
    this.initialImageBytes,
    this.initialImageSize,
  }) : super(key: key);

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

    if (widget.initialImageBytes != null && widget.initialImageSize != null) {
      _blackBgFaceImage = widget.initialImageBytes;
      _originalImageSize = widget.initialImageSize;
      _imageProvider = MemoryImage(widget.initialImageBytes!);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        setState(() {
          _removingBg = false;
          _showScanning = true;
          _loading = false;
        });
        _scanController.reset();
        _scanController.repeat();
        // Always analyze the zoomed face image
        await _analyzeImage(null, _blackBgFaceImage!);
        _scanController.reset();
        setState(() {
          _showScanning = false;
        });
      });
    }
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
                            ? "Processing..."
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

  Widget _buildImageArea(BuildContext context) {
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
                onGradioResult: (result) {
                  setState(() {
                    _gradioResult = result;
                  });
                },
                onViewPercentageSummary: () async {
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
                      var response =
                          await http.Response.fromStream(streamedResponse);
                      if (response.statusCode == 200) {
                        final decoded = json.decode(response.body);
                        return decoded;
                      }
                    } catch (e) {
                      return null;
                    }
                  }
                  return null;
                },
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: true,
              child: Container(height: 60, color: Colors.transparent),
            ),
          ),
        ],
      );
    }
    return ScanFaceScreen(
      onCameraPressed: _startCamera,
      onGalleryPressed: _pickImage,
    );
  }

  // Widget _buildCameraOverlay(BuildContext context) {
  //   return FutureBuilder<void>(
  //     future: _initializeControllerFuture,
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.done &&
  //           _cameraController != null) {
  //         return Container(
  //           child: Stack(
  //             children: [
  //               // Center(
  //               //   child: CameraPreview(_cameraController!),
  //               // ),
  //               Positioned.fill(
  //                 child: CameraPreview(_cameraController!),
  //               ),

  //               CustomPaint(
  //                 painter: OverlayPainter(),
  //                 child: Container(),
  //               ),
  //               Positioned(
  //                 left: 0,
  //                 right: 0,
  //                 top: 0,
  //                 child: Container(
  //                   padding:
  //                       const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
  //                   decoration: BoxDecoration(
  //                     gradient: LinearGradient(
  //                       begin: Alignment.topCenter,
  //                       end: Alignment.bottomCenter,
  //                       colors: [
  //                         Colors.black.withOpacity(0.85),
  //                         Colors.black.withOpacity(0.85),
  //                         Colors.black.withOpacity(0.85),
  //                         Colors.black.withOpacity(0.0),
  //                       ],
  //                     ),
  //                   ),
  //                   child: const Text(
  //                     'Set your face in the center of the circle',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                     textAlign: TextAlign.center,
  //                   ),
  //                 ),
  //               ),
  //               Positioned(
  //                 left: 0,
  //                 right: 0,
  //                 bottom: 0,
  //                 child: Container(
  //                   padding:
  //                       const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
  //                   decoration: BoxDecoration(
  //                     gradient: LinearGradient(
  //                       begin: Alignment.bottomCenter,
  //                       end: Alignment.topCenter,
  //                       colors: [
  //                         Colors.black.withOpacity(0.85),
  //                         Colors.black.withOpacity(0.85),
  //                         Colors.black.withOpacity(0.85),
  //                         Colors.black.withOpacity(0.0),
  //                       ],
  //                     ),
  //                   ),
  //                   child: SizedBox(
  //                     width: double.infinity,
  //                     child: ElevatedButton(
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Colors.white,
  //                         foregroundColor: Colors.black,
  //                         minimumSize: const Size.fromHeight(54),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(16),
  //                         ),
  //                         elevation: 0,
  //                       ),
  //                       onPressed: _captureAndAnalyze,
  //                       child: const Text(
  //                         'Capture & Analyze',
  //                         style: TextStyle(
  //                             fontSize: 18, fontWeight: FontWeight.w600),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       } else {
  //         return const Center(child: CircularProgressIndicator());
  //       }
  //     },
  //   );
  // }

  Widget _buildCameraOverlay(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _cameraController != null) {
          double cameraHeight = kIsWeb
              ? html.window.innerHeight?.toDouble() ??
                  MediaQuery.of(context).size.height
              : MediaQuery.of(context).size.height;

          return Container(
            width: double.infinity,
            height: cameraHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                CustomPaint(
                  painter: OverlayPainter(),
                  child: Container(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 42, horizontal: 24),
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 42, horizontal: 24),
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
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
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
      _removingBg = false;
      _showScanning = false;
    });

    // Always send to /zoom_face first, then use the result for analysis
    ZoomResult? zoomResult;
    if (bytes != null) {
      if (kIsWeb) {
        zoomResult = await _getBlackBgFaceFromBytes(bytes, picked.name);
      } else {
        zoomResult = await _getBlackBgFace(File(picked.path));
      }
    }

    if (zoomResult != null) {
      setState(() {
        _blackBgFaceImage = zoomResult!.bytes;
        _originalImageSize = zoomResult!.size;
        _imageProvider = MemoryImage(zoomResult!.bytes);
        _removingBg = true;
        _showScanning = true;
      });

      _scanController.reset();
      _scanController.repeat();

      // Always analyze the zoomed image
      await _analyzeImage(picked, zoomResult.bytes);

      _scanController.reset();
      setState(() {
        _showScanning = false;
      });
    } else {
      // fallback to original image if zoom/crop fails
      await _analyzeImage(picked, bytes);
      setState(() {
        _showScanning = false;
      });
    }
  }

  // Returns ZoomResult (bytes and size)
  Future<ZoomResult?> _getBlackBgFaceFromBytes(
      Uint8List imageBytes, String fileName) async {
    try {
      final uri =
          Uri.parse("https://harshadsalunkhe1212-fast-api.hf.space/zoom_face");
      final request = http.MultipartRequest("POST", uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final decodedImage = await decodeImageFromList(bytes);
        return ZoomResult(
          bytes,
          Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()),
        );
      } else {
        debugPrint('❌ Error from face crop API: ${response}');
        print("❌ Error from face crop API: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('⚠️ Failed to connect to face crop API: $e');
    }
    return null;
  }

  Future<ZoomResult?> _getBlackBgFace(File imageFile) async {
    try {
      final uri =
          Uri.parse("https://harshadsalunkhe1212-fast-api.hf.space/zoom_face");
      final request = http.MultipartRequest("POST", uri);
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final decodedImage = await decodeImageFromList(bytes);
        return ZoomResult(
          bytes,
          Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()),
        );
      } else {
        debugPrint('❌ Error from face crop API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to connect to face crop API: $e');
    }
    return null;
  }

  Future<Size> _getImageSizeMobileBytes(Uint8List bytes) async {
    final decodedImage = await decodeImageFromList(bytes);
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }

  Future<Size> _getImageSizeWeb(Uint8List bytes) async {
    final decodedImage = await decodeImageFromList(bytes);
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }

  Future<void> _analyzeImage(XFile? picked, Uint8List previewBytes) async {
    Map<String, dynamic>? ailabData;

    try {
      final uri =
          Uri.parse("https://harshadsalunkhe1212-fast-api.hf.space/predict");
      final filename = picked?.name ?? "image.jpg";
      final ext = filename.split('.').last.toLowerCase();
      final mimeType = ext == "png"
          ? "image/png"
          : ext == "webp"
              ? "image/webp"
              : ext == "gif"
                  ? "image/gif"
                  : "image/jpeg";

      if (kIsWeb) {
        final request = http.MultipartRequest('POST', uri);
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            previewBytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        );

        final response = await request.send();
        final resp = await http.Response.fromStream(response);

        if (resp.statusCode == 200) {
          final decoded = json.decode(resp.body);
          if (decoded is Map<String, dynamic>) {
            ailabData = decoded;
          } else if (decoded is List) {
            ailabData = {'results': decoded};
          }
        }
      } else {
        final req = http.MultipartRequest('POST', uri);
        req.files.add(http.MultipartFile.fromBytes(
          'image',
          previewBytes,
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
          }
        }
      }
    } catch (e, st) {
      print('API exception: $e\n$st');
      ailabData = null;
    }

    setState(() {
      _analysisJson = ailabData;
      _loading = false;
      _error = (_analysisJson == null)
          ? "Both APIs failed or returned no detections. Try again."
          : null;
      _imageProvider = MemoryImage(previewBytes);
      _scanningImageBytes = null;
    });

    // For upload API, keep reference of the zoomed/cropped image
    if (!kIsWeb) {
      _lastImageFile = picked != null ? File(picked.path) : null;
      _lastImageBytes = previewBytes;
    } else {
      _lastImageFile = picked != null ? File(picked.path) : null;
      _lastImageBytes = previewBytes;
    }
  }
}

class OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ovalWidth = size.width * (kIsWeb ? 0.95 : 0.8);
    final ovalHeight = size.height * (kIsWeb ? 0.85 : 0.65);
    final center = size.center(Offset.zero);
    final rect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final overlayPath = Path()..addRect(Offset.zero & size);
    final ovalPath = Path()..addOval(rect);
    final maskPath =
        Path.combine(PathOperation.difference, overlayPath, ovalPath);
    canvas.drawPath(maskPath, overlayPaint);

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
