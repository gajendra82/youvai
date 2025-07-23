import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/skin_analysis_screen.dart';

class ScanFaceScreen extends StatelessWidget {
  const ScanFaceScreen(
      {super.key, this.onCameraPressed, this.onGalleryPressed});

  final Function? onCameraPressed;
  final Function? onGalleryPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        // width: 340,
        margin: const EdgeInsets.symmetric(vertical: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Close Button Row
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     IconButton(
          //       icon: const Icon(Icons.close),
          //       onPressed: () => Navigator.of(context).pop(),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 10),
          // Title and Description
          const Text(
            "Scan your face",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
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
            height: 250,
            child: Image.asset(
              'assets/face_wireframe.png', // Use your asset path or use a placeholder if not available
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 18),
          // Tips Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.secondary, // purplish
                      child: const Text(
                        '1',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Good Lighting',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Good lighting for accurate and detailed scans.',
                            style:
                                TextStyle(fontSize: 13, color: Colors.black54),
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
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          Theme.of(context).primaryColor, // primary color
                      child: const Text(
                        '2',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Look Straight',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Consistency, alignment, and accuracy of the results.',
                            style:
                                TextStyle(fontSize: 13, color: Colors.black54),
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    "Camera",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    // print(onCamere);
                    if (onCameraPressed != null) {
                      print("Camera button pressed");
                      onCameraPressed!();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  label: const Text(
                    "Gallery",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    print("Gallery button pressed");
                    if (onGalleryPressed != null) {
                      onGalleryPressed!();
                    }
                  },
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
