// lib/screens/skin_analysis_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:skin_assessment/screens/SkinConditionResultPage.dart';
import 'package:skin_assessment/screens/scan_face_screen.dart';
import 'package:skin_assessment/widgets/web_auto_capture_camera_stub.dart'
    if (dart.library.html) 'package:skin_assessment/widgets/web_auto_capture_camera.dart';
import 'package:skin_assessment/models/face_detection_model.dart';
import 'package:skin_assessment/services/mobile_face_detection_service.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    with TickerProviderStateMixin {
  // Camera and UI state
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;
  bool _showCamera = false;
  ImageProvider? _imageProvider;
  Size? _originalImageSize;
  bool _loading = false;
  String? _error;

  // Scanning animation
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  Uint8List? _scanningImageBytes;

  // Face detection and analysis
  Uint8List? _faceImageBytes;
  Map<String, dynamic>? _skinAnalysisResult;

  // Mobile face detection
  MobileFaceDetectionService? _faceDetectionService;
  List<FaceBox> _detectedFaces = [];
  int _stableFaceCount = 0;
  Timer? _autoCaptureMobileTimer;
  bool _isAutoCapturingMobile = false;
  int _mobileCountdown = 3;
  static const int requiredStableFramesMobile = 15; // ~3s @ ~5fps

  // processing/capture guards (mobile)
  bool _processingFrame = false;
  bool _capturing = false;

  // Visual feedback animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _countdownController;
  late Animation<double> _countdownAnimation;

  @override
  void initState() {
    super.initState();
    _initCameras();
    _setupAnimations();

    // Initialize mobile face detection
    if (!kIsWeb) {
      _faceDetectionService = MobileFaceDetectionService();
    }

    // Handle initial image if provided
    if (widget.initialImageBytes != null && widget.initialImageSize != null) {
      _handleInitialImage();
    }
  }

  void _setupAnimations() {
    // Scanning animation
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

    // Pulse animation for buttons
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Countdown animation
    _countdownController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _countdownAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.easeInOut,
    ));
  }

  void _handleInitialImage() {
    _faceImageBytes = widget.initialImageBytes;
    _originalImageSize = widget.initialImageSize;
    _imageProvider = MemoryImage(widget.initialImageBytes!);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _loading = true;
      });
      _scanController.reset();
      _scanController.repeat();
      await _analyzeImageDirectAPI(null, _faceImageBytes!, _originalImageSize!);
      _scanController.reset();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  void _cleanup() {
    try {
      if (_cameraController?.value.isStreamingImages ?? false) {
        _cameraController!.stopImageStream();
      }
    } catch (_) {}
    _cameraController?.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    _countdownController.dispose();
    _faceDetectionService?.dispose();
    _autoCaptureMobileTimer?.cancel();
  }

  Future<void> _initCameras() async {
    if (kIsWeb) return; // web uses HTML video
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final cameras = await availableCameras();
      setState(() {
        _cameras = cameras;
      });
    } catch (_) {
      setState(() {
        _cameras = [];
      });
    }
  }

  Future<void> _startCamera() async {
    if (kIsWeb) {
      setState(() {
        _showCamera = true;
        _initializeControllerFuture = null; // web handled by widget
      });
      return;
    }

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

    _initializeControllerFuture = _cameraController!.initialize().then((_) {
      _startMobileFaceDetection();
    });

    setState(() {
      _showCamera = true;
    });
  }

  // --------- MOBILE: single stream + debounced detection ----------
  void _startMobileFaceDetection() {
    if (kIsWeb || _cameraController == null) return;
    if (_cameraController!.value.isStreamingImages) return;

    _stableFaceCount = 0;
    _isAutoCapturingMobile = false;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_processingFrame || _isAutoCapturingMobile) return;
      _processingFrame = true;

      try {
        if (_faceDetectionService == null) return;

        final faces = await _faceDetectionService!.detectFaces(image);
        if (!mounted) return;

        setState(() {
          _detectedFaces = faces;
        });

        final hasWellPositioned = faces.any((f) => f.isWellPositioned);

        if (hasWellPositioned) {
          _stableFaceCount++;
          if (_stableFaceCount >= requiredStableFramesMobile) {
            _startMobileAutoCapture(); // will stop stream before capture
          } else if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          _stableFaceCount = 0;
          if (_pulseController.isAnimating) {
            _pulseController.stop();
            _pulseController.reset();
          }
        }
      } catch (e) {
        debugPrint('Face detection error: $e');
      } finally {
        _processingFrame = false;
      }
    });
  }

  void _startMobileAutoCapture() {
    if (_isAutoCapturingMobile) return;

    setState(() {
      _isAutoCapturingMobile = true;
      _mobileCountdown = 3;
    });

    _countdownController
      ..reset()
      ..forward();

    _autoCaptureMobileTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      setState(() => _mobileCountdown--);

      if (_mobileCountdown <= 0) {
        timer.cancel();
        try {
          if (_cameraController != null &&
              _cameraController!.value.isStreamingImages) {
            await _cameraController!.stopImageStream();
            await Future.delayed(const Duration(milliseconds: 120));
          }
        } catch (_) {}
        await _captureAndAnalyze();
      } else {
        _countdownController
          ..reset()
          ..forward();
      }
    });
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_capturing) return;
    _capturing = true;

    try {
      // ensure stream stopped (idempotent)
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 120));
      }

      final image = await _cameraController!.takePicture();
      setState(() {
        _showCamera = false;
        _isAutoCapturingMobile = false;
      });
      await _processPickedImage(image, fromCamera: true);
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      _capturing = false;
    }
  }

  // ---------------- UI ----------------
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
              _buildScanningOverlay(),
            if (_loading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Positioned.fill(
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
                    painter: ScanningLinePainter(_scanAnimation.value),
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
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 18),
            Text(
              "Processing...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
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

    if (_faceImageBytes != null &&
        _originalImageSize != null &&
        _skinAnalysisResult != null) {
      return SkinConditionResultPage(
        gradioResult: _skinAnalysisResult!,
      );
    }

    return ScanFaceScreen(
      onCameraPressed: _startCamera,
      onGalleryPressed: _pickImage,
    );
  }

  Widget _buildCameraOverlay(BuildContext context) {
    if (kIsWeb) {
      return _buildWebCameraOverlay(context);
    } else {
      return _buildMobileCameraOverlay(context);
    }
  }

  Widget _buildWebCameraOverlay(BuildContext context) {
    final cameraHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      width: double.infinity,
      height: cameraHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: WebAutoCaptureCamera(
              onCaptured: (bytes, size) async {
                try {
                  setState(() {
                    _showCamera = false;
                    _scanningImageBytes = bytes;
                    _originalImageSize = size;
                    _faceImageBytes = bytes;
                    _loading = true;
                    _imageProvider = null;
                    _error = null;
                  });

                  _scanController
                    ..reset()
                    ..repeat();

                  await Future.delayed(const Duration(milliseconds: 80));
                  await _analyzeImageDirectAPI(null, bytes, size);

                  _scanController.reset();
                  if (mounted) {
                    setState(() {
                      _loading = false;
                    });
                  }
                } catch (error) {
                  _scanController.reset();
                  if (mounted) {
                    setState(() {
                      _loading = false;
                      _error = "Failed to process image: $error";
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Processing error: $error'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
            ),
          ),
          CustomPaint(
            painter: OverlayPainter(),
            child: Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCameraOverlay(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _cameraController != null) {
          final cameraHeight = MediaQuery.of(context).size.height;

          return SizedBox(
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
                ..._buildMobileFaceOverlays(context),
                _buildInstructionsOverlay(),
                if (_isAutoCapturingMobile) _buildMobileCountdownOverlay(),
                _buildCaptureButton(),
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  List<Widget> _buildMobileFaceOverlays(BuildContext context) {
    if (_detectedFaces.isEmpty) return [];

    final screenSize = MediaQuery.of(context).size;

    return _detectedFaces.map((face) {
      final left = face.x * screenSize.width;
      final top = face.y * screenSize.height;
      final width = face.width * screenSize.width;
      final height = face.height * screenSize.height;

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: face.isWellPositioned ? Colors.green : Colors.orange,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: face.isWellPositioned
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Perfect!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      );
    }).toList();
  }

  Widget _buildInstructionsOverlay() {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getMobileInstructionText(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCountdownOverlay() {
    return Center(
      child: AnimatedBuilder(
        animation: _countdownAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_countdownAnimation.value * 0.3),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.8),
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: Center(
                child: Text(
                  '$_mobileCountdown',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
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
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _hasWellPositionedFaceMobile()
                    ? _pulseAnimation.value
                    : 1.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasWellPositionedFaceMobile()
                        ? Colors.green
                        : Colors.white,
                    foregroundColor: _hasWellPositionedFaceMobile()
                        ? Colors.white
                        : Colors.black,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _captureAndAnalyze,
                  child: Text(
                    _hasWellPositionedFaceMobile()
                        ? 'Perfect! Tap to Capture'
                        : 'Capture & Analyze',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _hasWellPositionedFaceMobile() {
    return _detectedFaces.any((face) => face.isWellPositioned);
  }

  String _getMobileInstructionText() {
    if (_detectedFaces.isEmpty) {
      return 'Position your face in the camera';
    }

    final bestFace = _detectedFaces.firstWhere(
      (face) => face.isWellPositioned,
      orElse: () => _detectedFaces.first,
    );

    if (bestFace.isWellPositioned) {
      if (_isAutoCapturingMobile) {
        return 'Hold still! Capturing in $_mobileCountdown...';
      } else {
        return 'Perfect position! Auto-capture starting...';
      }
    }

    final centerX = bestFace.x + bestFace.width / 2;
    final centerY = bestFace.y + bestFace.height / 2;

    if (bestFace.width < 0.15 || bestFace.height < 0.15) {
      return 'Move closer to the camera';
    } else if (bestFace.width > 0.8 || bestFace.height > 0.8) {
      return 'Move away from the camera';
    } else if ((centerX - 0.5).abs() > 0.3) {
      return centerX < 0.5 ? 'Move right' : 'Move left';
    } else if ((centerY - 0.5).abs() > 0.3) {
      return centerY < 0.5 ? 'Move down' : 'Move up';
    } else {
      return 'Almost there! Hold still...';
    }
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
      _imageProvider = null;
      _faceImageBytes = bytes;
    });

    _scanController
      ..reset()
      ..repeat();
    await _analyzeImageDirectAPI(picked, bytes, size);
    _scanController.reset();

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _analyzeImageDirectAPI(
      XFile? picked, Uint8List previewBytes, Size imageSize) async {
    Map<String, dynamic>? resultJson;
    try {
      final uri = Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/analyze-skin');

      var request = http.MultipartRequest('POST', uri);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? guestId = prefs.getString('guest_id');
      String? token = prefs.getString('_token');

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      } else if (guestId == null) {
        guestId =
            'guest_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100000)}';
        await prefs.setString('guest_id', guestId);
      }

      if (guestId != null) {
        request.fields['guest_id'] = guestId;
      }

      final fileName = picked != null ? basename(picked.path) : 'capture.jpg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          previewBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        resultJson = decoded is Map<String, dynamic> ? decoded : null;

        if (resultJson == null || resultJson.isEmpty) {
          if (mounted) {
            setState(() {
              _error = "No analysis data returned from server";
              _loading = false;
            });
          }
          return;
        }
      } else {
        if (mounted) {
          setState(() {
            _error = "Server error: ${response.statusCode}";
            _loading = false;
          });
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Network error: $e";
          _loading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _skinAnalysisResult = resultJson;
        _loading = false;
        _error = null;
        _imageProvider = MemoryImage(previewBytes);
        _scanningImageBytes = null;
        _faceImageBytes = previewBytes;
        _originalImageSize = imageSize;
      });
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

    _drawDashedOvalBorder(canvas, rect, dashPaint);
    _drawFaceGuides(canvas, rect);
  }

  void _drawDashedOvalBorder(Canvas canvas, Rect rect, Paint paint) {
    const dashLength = 15.0;
    const gapLength = 10.0;

    final a = rect.width / 2;
    final b = rect.height / 2;
    final circumference = pi * (3 * (a + b) - sqrt((3 * a + b) * (a + 3 * b)));

    final dashCount = (circumference / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle =
          (i * (dashLength + gapLength)) / (circumference / (2 * pi));
      final endAngle = startAngle + (dashLength / (circumference / (2 * pi)));

      final path = Path();
      path.addArc(rect, startAngle, endAngle - startAngle);
      canvas.drawPath(path, paint);
    }
  }

  void _drawFaceGuides(Canvas canvas, Rect rect) {
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final center = rect.center;

    canvas.drawCircle(
      Offset(center.dx - rect.width * 0.15, center.dy - rect.height * 0.08),
      2,
      guidePaint,
    );

    canvas.drawCircle(
      Offset(center.dx + rect.width * 0.15, center.dy - rect.height * 0.08),
      2,
      guidePaint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy + rect.height * 0.05),
      Offset(center.dx, center.dy + rect.height * 0.12),
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 1.5,
    );
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
