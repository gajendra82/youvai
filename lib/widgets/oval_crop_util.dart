import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

/// Crop an oval region from a camera image file using the coordinates of the oval overlay on the preview.
/// Returns PNG bytes with transparency outside the oval.
///
/// [imagePath] is the path to the captured camera image.
/// [widgetSize] is the size of the camera preview widget (e.g. MediaQuery.of(context).size).
/// [ovalRectOnWidget] is the Rect of the oval overlay (in widget coordinates, same as OverlayPainter).
Future<Uint8List> cropOvalFromCameraImage({
  required String imagePath,
  required Size widgetSize,
  required Rect ovalRectOnWidget,
}) async {
  // Load the camera image as bytes
  final imgBytes = await File(imagePath).readAsBytes();
  final original = img.decodeImage(imgBytes);
  if (original == null) throw Exception("Failed to decode image");

  // Calculate scale between widget (preview) and camera image
  final scaleX = original.width / widgetSize.width;
  final scaleY = original.height / widgetSize.height;

  // Map the oval rect from widget coordinates to image coordinates
  final cropLeft = (ovalRectOnWidget.left * scaleX).round();
  final cropTop = (ovalRectOnWidget.top * scaleY).round();
  final cropWidth = (ovalRectOnWidget.width * scaleX).round();
  final cropHeight = (ovalRectOnWidget.height * scaleY).round();

  // Crop the bounding rectangle of the oval
  final cropped = img.copyCrop(
    original,
    x: cropLeft,
    y: cropTop,
    width: cropWidth,
    height: cropHeight,
  );

  // Prepare for oval mask math
  final centerX = cropped.width / 2.0;
  final centerY = cropped.height / 2.0;
  final radiusX = cropped.width / 2.0;
  final radiusY = cropped.height / 2.0;

  final output = img.Image(
    width: cropped.width,
    height: cropped.height,
    numChannels: 4,
  );

  for (int y = 0; y < cropped.height; y++) {
    for (int x = 0; x < cropped.width; x++) {
      // Ellipse math: ((x-h)/a)^2 + ((y-k)/b)^2 <= 1
      final dx = (x - centerX) / radiusX;
      final dy = (y - centerY) / radiusY;
      if (dx * dx + dy * dy <= 1.0) {
        output.setPixel(x, y, cropped.getPixel(x, y));
      } else {
        output.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0)); // transparent
      }
    }
  }

  // Encode as PNG (to preserve transparency)
  return Uint8List.fromList(img.encodePng(output));
}
