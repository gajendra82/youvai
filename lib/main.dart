import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/skin_analysis_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Analysis',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SkinAnalysisScreen(),
    );
  }
}
