import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
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
  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  StreamSubscription<html.MessageEvent>? _messageSubscription;
  Timer? _pollingTimer;
  bool _isInitialized = false;
  String _status = 'Initializing camera...';

  @override
  void initState() {
    super.initState();
    print('WebAutoCaptureCamera: initState');
    _initializeCamera();
    _setupMessageListener();
    _startPolling();
  }

  void _setupMessageListener() {
    print('WebAutoCaptureCamera: Setting up listeners...');

    // Standard message listener
    _messageSubscription =
        html.window.onMessage.listen((html.MessageEvent event) {
      _processMessage(event.data, 'postMessage');
    });

    // Custom event listener
    html.window.addEventListener('flutter_face_captured', (event) {
      if (event is html.CustomEvent) {
        _processMessage(event.detail, 'customEvent');
      }
    });
  }

  void _startPolling() {
    print('WebAutoCaptureCamera: Starting polling system...');

    _pollingTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _checkAllDataSources();
    });
  }

  void _checkAllDataSources() {
    // Check localStorage
    try {
      final stored = html.window.localStorage['flutter_face_capture'];
      if (stored != null && stored.isNotEmpty) {
        print('WebAutoCaptureCamera: Found data in localStorage');
        final data = json.decode(stored);
        html.window.localStorage.remove('flutter_face_capture');
        html.window.localStorage.remove('flutter_capture_timestamp');
        _processMessage(data, 'localStorage');
        return;
      }
    } catch (error) {
      // Ignore
    }

    // Check sessionStorage
    try {
      final stored = html.window.sessionStorage['flutter_face_capture'];
      if (stored != null && stored.isNotEmpty) {
        print('WebAutoCaptureCamera: Found data in sessionStorage');
        final data = json.decode(stored);
        html.window.sessionStorage.remove('flutter_face_capture');
        _processMessage(data, 'sessionStorage');
        return;
      }
    } catch (error) {
      // Ignore
    }

    // Check global variable
    try {
      final data = js_util.getProperty(html.window, 'flutterCaptureData');
      if (data != null) {
        print('WebAutoCaptureCamera: Found data in global variable');
        js_util.setProperty(html.window, 'flutterCaptureData', null);
        _processMessage(data, 'globalVariable');
        return;
      }
    } catch (error) {
      // Ignore
    }
  }

  void _processMessage(dynamic data, String source) {
    try {
      Map<String, dynamic> messageData;

      if (data is String) {
        messageData = json.decode(data);
      } else if (data is Map<String, dynamic>) {
        messageData = data;
      } else {
        return;
      }

      print(
          'WebAutoCaptureCamera: Processing ${messageData['type']} from $source');

      switch (messageData['type']) {
        case 'face_captured':
          print('WebAutoCaptureCamera: Processing face capture from $source');
          _handleImageCapture(messageData);
          break;
        case 'blazeface_detection':
          _handleFaceDetection(messageData);
          break;
      }
    } catch (error) {
      print(
          'WebAutoCaptureCamera: Error processing message from $source: $error');
    }
  }

  void _sendConfirmationToJS(String confirmationType) {
    print('WebAutoCaptureCamera: Sending confirmation: $confirmationType');

    try {
      final message = {
        'type': 'flutter_$confirmationType',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Send via multiple methods
      html.window.postMessage(message, '*');

      final parentWindow = html.window.parent;
      if (parentWindow != null && parentWindow != html.window) {
        parentWindow.postMessage(message, '*');
      }

      // Also dispatch custom event
      final event = html.CustomEvent('flutter_confirmation', detail: message);
      html.window.dispatchEvent(event);

      print('WebAutoCaptureCamera: Confirmation sent via all methods');
    } catch (error) {
      print('WebAutoCaptureCamera: Error sending confirmation: $error');
    }
  }

  void _handleImageCapture(Map<String, dynamic> data) {
    print('WebAutoCaptureCamera: === HANDLING IMAGE CAPTURE ===');

    // Stop polling immediately
    _pollingTimer?.cancel();

    // Send immediate confirmation that we received the message
    _sendConfirmationToJS('processing_started');

    try {
      final String? base64Data = data['imageData'];
      final dynamic widthData = data['width'];
      final dynamic heightData = data['height'];

      print('WebAutoCaptureCamera: Capture data:');
      print('  - base64 length: ${base64Data?.length ?? 'null'}');
      print('  - width: $widthData');
      print('  - height: $heightData');
      print('  - timestamp: ${data['timestamp']}');

      if (base64Data == null || base64Data.isEmpty) {
        throw Exception('No image data received');
      }

      final int width = _parseToInt(widthData);
      final int height = _parseToInt(heightData);

      if (width <= 0 || height <= 0) {
        throw Exception('Invalid dimensions: ${width}x$height');
      }

      print('WebAutoCaptureCamera: Decoding base64...');
      final Uint8List imageBytes = base64Decode(base64Data);
      print('WebAutoCaptureCamera: Decoded ${imageBytes.length} bytes');

      final Size imageSize = Size(width.toDouble(), height.toDouble());

      setState(() {
        _status = 'Image captured! Processing...';
      });

      print('WebAutoCaptureCamera: === CALLING FLUTTER CALLBACK ===');

      // Call callback in next frame to ensure UI updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          print('WebAutoCaptureCamera: Executing onCaptured callback...');
          widget.onCaptured(imageBytes, imageSize);
          print('WebAutoCaptureCamera: === CALLBACK COMPLETED ===');

          // Send confirmation that processing is complete
          _sendConfirmationToJS('processing_complete');

          setState(() {
            _status = 'Processing complete!';
          });
        } catch (callbackError, stackTrace) {
          print('WebAutoCaptureCamera: === CALLBACK ERROR ===');
          print('WebAutoCaptureCamera: Error: $callbackError');
          print('WebAutoCaptureCamera: Stack trace: $stackTrace');

          // Still send completion confirmation even if there was an error
          _sendConfirmationToJS('processing_complete');

          setState(() {
            _status = 'Processing error: $callbackError';
          });
        }
      });
    } catch (error, stackTrace) {
      print('WebAutoCaptureCamera: === IMAGE PROCESSING ERROR ===');
      print('WebAutoCaptureCamera: Error: $error');
      print('WebAutoCaptureCamera: Stack trace: $stackTrace');

      // Send completion confirmation even on error
      _sendConfirmationToJS('processing_complete');

      setState(() {
        _status = 'Capture failed: $error';
      });
    }
  }

  int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _handleFaceDetection(Map<String, dynamic> data) {
    try {
      final List<dynamic> boxes = data['boxes'] ?? [];
      setState(() {
        if (boxes.isEmpty) {
          _status = 'Position your face in the camera';
        } else {
          final bool hasWellPositioned =
              boxes.any((box) => _isWellPositioned(box));
          if (hasWellPositioned) {
            _status = 'Perfect position! Hold still...';
          } else {
            _status = 'Adjust your position';
          }
        }
      });
    } catch (error) {
      print('WebAutoCaptureCamera: Face detection error: $error');
    }
  }

  bool _isWellPositioned(dynamic box) {
    if (box is! Map<String, dynamic>) return false;

    final double width = (box['width'] ?? 0.0).toDouble();
    final double height = (box['height'] ?? 0.0).toDouble();
    final double x = (box['x'] ?? 0.0).toDouble();
    final double y = (box['y'] ?? 0.0).toDouble();

    if (width < 0.15 || height < 0.15 || width > 0.8 || height > 0.8) {
      return false;
    }

    final double centerX = x + width / 2;
    final double centerY = y + height / 2;

    return (centerX - 0.5).abs() <= 0.25 && (centerY - 0.5).abs() <= 0.25;
  }

  Future<void> _initializeCamera() async {
    try {
      print('WebAutoCaptureCamera: Requesting camera...');

      _stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'facingMode': 'user',
        }
      });

      if (_stream != null) {
        print('WebAutoCaptureCamera: Camera granted');

        _videoElement = html.VideoElement()
          ..srcObject = _stream
          ..autoplay = true
          ..muted = true;

        _videoElement!.setAttribute('playsinline', 'true');
        await _videoElement!.onLoadedMetadata.first;

        print(
            'WebAutoCaptureCamera: Video ready: ${_videoElement!.videoWidth}x${_videoElement!.videoHeight}');

        html.document.body!.children.add(_videoElement!);

        _videoElement!.style
          ..position = 'fixed'
          ..top = '0'
          ..left = '0'
          ..width = '100%'
          ..height = '100%'
          ..objectFit = 'cover'
          ..zIndex = '1'
          ..transform = 'scaleX(-1)';

        setState(() {
          _isInitialized = true;
          _status = 'Camera ready';
        });

        await Future.delayed(const Duration(milliseconds: 1000));
        _startFaceDetection();
      } else {
        throw Exception('Camera access denied');
      }
    } catch (error, stackTrace) {
      print('WebAutoCaptureCamera: Camera error: $error');
      setState(() {
        _status = 'Camera error: $error';
      });
    }
  }

  void _startFaceDetection() {
    print('WebAutoCaptureCamera: Starting face detection...');
    try {
      html.window.postMessage({
        'type': 'start_face_detection',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, '*');

      setState(() {
        _status = 'Looking for face...';
      });
    } catch (error) {
      print('WebAutoCaptureCamera: Start detection error: $error');
    }
  }

  void _manualCapture() {
    print('WebAutoCaptureCamera: Manual capture requested');
    try {
      html.window.postMessage({
        'type': 'capture_now',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, '*');
    } catch (error) {
      print('WebAutoCaptureCamera: Manual capture error: $error');
    }
  }

  @override
  void dispose() {
    print('WebAutoCaptureCamera: Disposing...');

    _pollingTimer?.cancel();

    try {
      html.window.postMessage({'type': 'stop_face_detection'}, '*');
    } catch (error) {
      print('WebAutoCaptureCamera: Stop error: $error');
    }

    _videoElement?.remove();
    _stream?.getTracks().forEach((track) => track.stop());
    _messageSubscription?.cancel();

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
