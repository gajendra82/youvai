import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skin_assessment/screens/face_view.dart';
import 'dart:io';

import 'package:skin_assessment/screens/scan_face_screen.dart';

class CameraTabScreen extends StatefulWidget {
  const CameraTabScreen({Key? key}) : super(key: key);

  @override
  State<CameraTabScreen> createState() => _CameraTabScreenState();
}

class _CameraTabScreenState extends State<CameraTabScreen> {
  @override
  void initState() {
    super.initState();
    _showDialogAndPickImage();
  }

  File? _imageFile;

  Future<void> _showDialogAndPickImage() async {
    Future.delayed(const Duration(milliseconds: 100), () {
      showScanFaceDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _imageFile == null
            ? ElevatedButton(
                onPressed: _showDialogAndPickImage,
                child: const Text('Scan'),
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 100,
                    child: Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(
                          Icons.analytics_outlined,
                          color: Colors.black,
                          size: 30,
                        ),
                        label: const Text(
                          "Start Analysis",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ScanFaceScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      child: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<bool?> showScanFaceDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 8),
              // Title
              const Text(
                "Scan your face",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Description
              const Text(
                "We use the results of your facial scan to find out problems and get product recommendations from us",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Face wireframe image
              SizedBox(
                height: 120,
                child: Image.asset(
                  'assets/face_wireframe.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 18),
              // Tips Card
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tip 1
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xff7c6cc6),
                          child: Text(
                            '1',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Lighting',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Good lighting for accurate and detailed scans.',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tip 2
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xff7c6cc6),
                          child: Text(
                            '2',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Look Straight',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Consistency, alignment, and accuracy of the results.',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Scan Now Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff7c6cc6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FaceViewPage(
                          // skinAnnotations: [
                          //   SkinIssueAnnotation(
                          //     label: 'Dead skin cells',
                          //     position: Offset(60, 350),
                          //     direction: ArrowDirection.right,
                          //   ),
                          //   SkinIssueAnnotation(
                          //     label: 'Dry patches',
                          //     position: Offset(260, 200),
                          //     direction: ArrowDirection.left,
                          //   ),
                          //   // Add more points as needed
                          // ],
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Scan now!",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
