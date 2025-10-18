import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:youv_ai/models/face_detection_model.dart';

class MobileFaceDetectionService {
  late FaceDetector _faceDetector;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        enableClassification: false,
        enableTracking: true,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    _isInitialized = true;
  }

  Future<List<FaceBox>> detectFaces(CameraImage image) async {
    if (!_isInitialized) await initialize();

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return [];

    try {
      final faces = await _faceDetector.processImage(inputImage);

      return faces.map((face) {
        final boundingBox = face.boundingBox;
        return FaceBox(
          x: boundingBox.left / image.width,
          y: boundingBox.top / image.height,
          width: boundingBox.width / image.width,
          height: boundingBox.height / image.height,
          confidence: 1.0, // ML Kit doesn't provide confidence scores
        );
      }).toList();
    } catch (e) {
      print('Error detecting faces: $e');
      return [];
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = CameraDescription(
      name: 'front',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 0,
    );

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void dispose() {
    if (_isInitialized) {
      _faceDetector.close();
    }
  }
}
