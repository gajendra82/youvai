// lib/widgets/web_auto_capture_camera.dart
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class WebAutoCaptureCamera extends StatefulWidget {
  final Function(Uint8List imageBytes, Size imageSize) onCaptured;

  const WebAutoCaptureCamera({
    Key? key,
    required this.onCaptured,
  }) : super(key: key);

  @override
  State<WebAutoCaptureCamera> createState() => _WebAutoCaptureCameraState();
}

class _WebAutoCaptureCameraState extends State<WebAutoCaptureCamera> {
  static const _videoId = 'flutter-webcam-video';

  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  StreamSubscription<html.MessageEvent>? _messageSubscription;

  bool _isInitialized = false;
  bool _hasCaptured = false;
  String _status = 'Initializing camera...';

  Timer? _detectorKickTimer; // fallback kick if JS didn’t start
  bool _jsSeenAnyEvent = false; // did we hear back from JS at least once?

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
    _initializeCamera();
  }

  void _setupMessageListener() {
    _messageSubscription =
        html.window.onMessage.listen((html.MessageEvent event) {
      dynamic raw = event.data;

      // Accept Map or JSON string
      Map<String, dynamic>? data;
      if (raw is Map) {
        data = raw.cast<String, dynamic>();
      } else if (raw is String) {
        try {
          final parsed = jsonDecode(raw);
          if (parsed is Map) data = parsed.cast<String, dynamic>();
        } catch (_) {}
      }
      if (data == null) return;

      final type = data['type'] as String?;
      if (type == null) return;

      // mark that JS is alive
      _jsSeenAnyEvent = true;

      switch (type) {
        case 'blazeface_detection':
          final hasWell = data['hasWellPositioned'] == true;
          final List boxes = (data['boxes'] as List?) ?? const [];
          if (!mounted) return;
          setState(() {
            _status = boxes.isEmpty
                ? 'Position your face in the oval'
                : (hasWell
                    ? 'Perfect position! Hold still...'
                    : 'Adjust your position');
          });
          break;

        case 'face_captured':
          if (_hasCaptured) return;
          _hasCaptured = true;

          // Stop camera immediately
          _stopCamera();

          try {
            final base64Data = data['imageData'] as String;
            final int w = (data['width'] as num).toInt();
            final int h = (data['height'] as num).toInt();
            final bytes = base64Decode(base64Data);
            widget.onCaptured(bytes, Size(w.toDouble(), h.toDouble()));
            if (!mounted) return;
            setState(() => _status = 'Processing complete!');
          } catch (e) {
            if (!mounted) return;
            setState(() => _status = 'Processing error: $e');
          }
          break;

        case 'detector_error':
          if (!mounted) return;
          setState(() => _status = 'Detector error: ${data!['message']}');
          break;
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      // Request user-facing camera
      _stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'facingMode': 'user',
        },
        'audio': false,
      });

      if (_stream == null) {
        if (!mounted) return;
        setState(() => _status = 'Camera permission denied');
        return;
      }

      // Create & attach video
      _videoElement = html.VideoElement()
        ..id = _videoId
        ..srcObject = _stream
        ..autoplay = true
        ..muted = true;

      _videoElement!.setAttribute('playsinline', 'true');

      // Append to DOM first (important for some browsers)
      html.document.body!.append(_videoElement!);

      // Styling (mirrored preview)
      _videoElement!.style
        ..position = 'fixed'
        ..top = '0'
        ..left = '0'
        ..width = '100%'
        ..height = '100%'
        ..objectFit = 'cover'
        ..zIndex = '1'
        ..transform = 'scaleX(-1)';

      // Wait for metadata, then ensure playback
      await _videoElement!.onLoadedMetadata.first;
      // Some browsers still need an explicit play()
      try {
        await _videoElement!.play();
      } catch (_) {
        // If autoplay is blocked, the user will need to tap "Capture Now"
      }

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _status = 'Camera ready. Looking for your face...';
      });

      // Post start after a short delay to ensure the element is ready
      Future.delayed(const Duration(milliseconds: 50), _postStartDetection);

      // Safety net: if we don’t hear from JS in 2s, post again
      _detectorKickTimer?.cancel();
      _detectorKickTimer = Timer(const Duration(seconds: 2), () {
        if (!_jsSeenAnyEvent) {
          _postStartDetection();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Camera error: $e');
    }
  }

  void _postStartDetection() {
    _postToJs({
      'type': 'start_face_detection',
      'videoId': _videoId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _postToJs(Map<String, dynamic> msg) {
    // Same-origin; '*' is fine because we control the page
    html.window.postMessage(msg, '*');
  }

  void _manualCapture() {
    _postToJs({
      'type': 'capture_now',
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }

  Future<void> _stopCamera() async {
    try {
      _stream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    try {
      _videoElement?.remove();
    } catch (_) {}
    _stream = null;
    _videoElement = null;
  }

  @override
  void dispose() {
    _detectorKickTimer?.cancel();
    _postToJs({'type': 'stop_face_detection'});
    _messageSubscription?.cancel();
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          if (!_isInitialized)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isInitialized ? _manualCapture : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Capture Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
