import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:youv_ai/screens/SkinConditionResultPage.dart';
import 'package:youv_ai/screens/scan_face_screen.dart';
import '../models/skin_analysis_model.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youv_ai/bloc/auth/auth_bloc.dart';
import 'package:youv_ai/bloc/auth/auth_state.dart';
import 'package:youv_ai/utils/app_routes.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

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
  List<CameraDescription>? _cameras;
  bool _camerasReady = false;
  bool _showCamera = false;
  bool _isCameraInitializing = false;
  XFile? _capturedImage;

  ImageProvider? _imageProvider;
  Size? _originalImageSize;
  bool _loading = false;
  String? _error;
  SkinIssueType? _selectedIssueType;
  File? _lastImageFile;
  Uint8List? _lastImageBytes;

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  Uint8List? _scanningImageBytes;

  Uint8List? _faceImageBytes;
  bool _removingBg = false;
  bool _showScanning = false;

  Map<String, dynamic>? _skinAnalysisResult;
  Map<String, dynamic>? _faceRatioResult;

  @override
  void initState() {
    super.initState();
    _initCameras();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    if (widget.initialImageBytes != null && widget.initialImageSize != null) {
      _faceImageBytes = widget.initialImageBytes;
      _originalImageSize = widget.initialImageSize;
      _imageProvider = MemoryImage(widget.initialImageBytes!);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        setState(() {
          _removingBg = false;
          _showScanning = true;
          _loading = true;
        });
        _scanController
          ..reset()
          ..repeat();
        await _analyzeImageDirectAPI(
            null, _faceImageBytes!, _originalImageSize!);
        _scanController.stop();
        setState(() {
          _showScanning = false;
        });
      });
    }
    // _showDisclaimerPopup();
  }

  Future<Map<String, dynamic>?> _callVerticalRatio(Uint8List bytes,
      {String filename = 'upload.jpg'}) async {
    try {
      final uri = Uri.parse(
          'https://anujakkulkarni-symmetry.hf.space/analyze?draw=0'); // draw=0 => raw crop
      final req = http.MultipartRequest('POST', uri);
      req.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: http_parser.MediaType('image', 'jpeg'),
      ));

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      } else {
        debugPrint('Symmetry API failed: ${res.statusCode} ${res.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Symmetry API error: $e');
      return null;
    }
  }

  void _showDisclaimerPopup() {
    showDialog(
      context: this.context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Disclaimer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(
              child: const Text(
                'The Attractiveness Index and face/skin analysis provided by this application are AI-generated estimates for informational and entertainment purposes only.\n\n'
                'Results do not represent a medical diagnosis, dermatological assessment, or professional beauty advice.\n\n'
                'Factors such as lighting, camera quality, and environmental conditions may influence the outcome.\n\n'
                'Users should not rely solely on this analysis for making decisions regarding skincare, medical treatments, or personal wellbeing.\n\n'
                'For any medical or cosmetic concerns, please consult a qualified healthcare or skincare professional.\n\n'
                'The Service Provider makes no guarantees regarding accuracy, completeness, or suitability of the AI analysis.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // After closing disclaimer, navigate to results
                // if (!_openedResultPage) {
                //   _openedResultPage = true;
                //   Navigator.of(context).pushReplacement(
                //     MaterialPageRoute(
                //       builder: (_) => SkinConditionResultPage(
                //         gradioResult: widget.analysisJson,
                //       ),
                //     ),
                //   );
                // }
              },
              child: const Text(
                'I Understand',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _initCameras() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final cameras = await availableCameras();
      setState(() {
        _cameras = cameras;
        _camerasReady = true;
      });
    } catch (e) {
      setState(() {
        _cameras = [];
        _camerasReady = true;
      });
    }
  }

  Future<void> _startCamera() async {
    if (_isCameraInitializing) return;
    if (_cameras == null || _cameras!.isEmpty) return;

    setState(() {
      _isCameraInitializing = true;
    });

    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }

      final frontCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        _showCamera = true;
      });
    } catch (e) {
      print("Error starting camera: $e");
      setState(() {
        _showCamera = false;
      });
    } finally {
      setState(() {
        _isCameraInitializing = false;
      });
    }
  }

  Future<void> _closeCamera() async {
    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      print("Error closing camera: $e");
    }
    setState(() {
      _showCamera = false;
    });
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    final image = await _cameraController!.takePicture();
    await _closeCamera();
    setState(() {
      _capturedImage = image;
    });
    await _processPickedImage(image, fromCamera: true);
  }

  @override
  Widget build(BuildContext context) {
    // ADD BLOC LISTENER HERE
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLogout) {
          if (ModalRoute.of(context)?.isCurrent == true) {
            Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.onboard, (route) => false);
          }
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          if (_showCamera) {
            await _closeCamera();
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor:
              (_imageProvider == null) ? Colors.white : Colors.black,
          body: SafeArea(
            child: !_camerasReady
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Loading camera...",
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  )
                : Stack(
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
                      if (_isCameraInitializing)
                        Container(
                          color: Colors.black.withOpacity(0.6),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  "Opening camera...",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_loading && _imageProvider != null)
                        Positioned.fill(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image(
                                  image: _imageProvider!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Container(color: Colors.black.withOpacity(0.6)),
                              AnimatedBuilder(
                                animation: _scanController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: ScanningLinePainter(
                                        _scanAnimation.value),
                                    size: MediaQuery.of(context).size,
                                  );
                                },
                              ),
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.4),
                                            width: 2,
                                          ),
                                        ),
                                        child: AnimatedBuilder(
                                          animation: _scanController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: 0.9 +
                                                  (_scanAnimation.value * 0.1),
                                              child: const Icon(
                                                Icons.psychology,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        "AI Analysis in Progress",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "Our advanced AI model is carefully analyzing your skin condition. This will take just a few moments...",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildStatusDot(true),
                                          const SizedBox(width: 8),
                                          _buildStatusDot(
                                              _scanAnimation.value > 0.3),
                                          const SizedBox(width: 8),
                                          _buildStatusDot(
                                              _scanAnimation.value > 0.6),
                                          const SizedBox(width: 8),
                                          _buildStatusDot(
                                              _scanAnimation.value > 0.9),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
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
    if (_faceImageBytes != null &&
        _originalImageSize != null &&
        _skinAnalysisResult != null) {
      // SkinConditionResultPage is also wrapped with BlocListener inside its file
      return SkinConditionResultPage(
        gradioResult: _skinAnalysisResult!,
        faceRatioJson: _faceRatioResult, // ← add this (optional)
      );
    }
    return ScanFaceScreen(
      onCameraPressed: _startCamera,
      onGalleryPressed: _pickImage,
      isCameraInitializing: _isCameraInitializing,
    );
  }

  Widget _buildCameraOverlay(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    double cameraHeight = kIsWeb
        ? html.window.innerHeight?.toDouble() ??
            MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      height: cameraHeight,
      child: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_cameraController!)),
          CustomPaint(painter: OverlayPainter(), child: Container()),
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: _closeCamera,
            ),
          ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Text(
                  'Set your face in the center of the circle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
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
                    Colors.black.withOpacity(0.0),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
      _loading = true;
      _imageProvider = MemoryImage(bytes!);
      _faceImageBytes = bytes;
      _removingBg = false;
      _showScanning = false;
    });

    _scanController
      ..reset()
      ..repeat();

    await _analyzeImageDirectAPI(picked, bytes!, size!);

    _scanController.stop();

    setState(() {
      _showScanning = false;
      _loading = false;
      _removingBg = true;
    });
  }

  Future<void> _analyzeImageDirectAPI(
      XFile? picked, Uint8List previewBytes, Size imageSize) async {
    Map<String, dynamic>? resultJson; // skin API result
    Map<String, dynamic>? faceRatioJson; // symmetry API result

    try {
      // --------- Build skin API request (but don't await yet) ----------
      final skinUri = Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/analyze-skin');

      final skinRequest = http.MultipartRequest('POST', skinUri);

      final prefs = await SharedPreferences.getInstance();
      String? guestId = prefs.getString('guest_id');
      String? token = prefs.getString('_token');

      if (token != null) {
        skinRequest.headers['Authorization'] = 'Bearer $token';
      } else if (guestId == null) {
        guestId =
            'guest_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100000)}';
        await prefs.setString('guest_id', guestId);
        skinRequest.fields['guest_id'] = guestId;
      }

      skinRequest.files.add(
        http.MultipartFile.fromBytes(
          'file',
          previewBytes,
          filename: picked != null ? basename(picked.path) : 'upload.jpg',
        ),
      );

      // ---------- Kick off both calls *in parallel* ----------
      final skinFuture = (() async {
        final streamed = await skinRequest.send();
        final res = await http.Response.fromStream(streamed);
        if (res.statusCode == 200) {
          return json.decode(res.body) as Map<String, dynamic>;
        } else {
          debugPrint('Skin API failed: ${res.statusCode} ${res.body}');
          return null;
        }
      })();

      final symmetryFuture = _callVerticalRatio(previewBytes,
          filename: picked?.name ?? 'upload.jpg');

      final results = await Future.wait([skinFuture, symmetryFuture]);

      resultJson = results[0] as Map<String, dynamic>?;
      faceRatioJson = results[1] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint("Parallel analyze error: $e");
    }

    // -------------- Update state / show results --------------
    setState(() {
      _skinAnalysisResult = resultJson;
      _faceRatioResult = faceRatioJson; // ← save symmetry JSON
      _loading = false;

      _error = (_skinAnalysisResult == null)
          ? "API failed or returned no detections. Try again."
          : null;

      _imageProvider = MemoryImage(previewBytes);
      _scanningImageBytes = null;
      _faceImageBytes = previewBytes;
      _originalImageSize = imageSize;
      _lastImageBytes = previewBytes;
      if (!kIsWeb) {
        _lastImageFile = picked != null ? File(picked.path) : null;
      } else {
        _lastImageFile = null;
      }
    });
  }

  Future<Size> _getImageSizeMobileBytes(Uint8List bytes) async {
    final decodedImage = await decodeImageFromList(bytes);
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }

  Future<Size> _getImageSizeWeb(Uint8List bytes) async {
    final decodedImage = await decodeImageFromList(bytes);
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }
}

// --- Overlay Painter ---
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

    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.35);
    final overlayPath = Path()..addRect(Offset.zero & size);
    final ovalPath = Path()..addOval(rect);
    final maskPath =
        Path.combine(PathOperation.difference, overlayPath, ovalPath);
    canvas.drawPath(maskPath, overlayPaint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawOval(rect, clearPaint);

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

// --- Scanning Line Painter ---
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
