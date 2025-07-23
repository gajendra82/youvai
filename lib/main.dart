import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/skin_analysis_screen.dart';
import 'package:skin_assessment/themes/app_theme.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:skin_assessment/screens/home_page.dart';
import 'package:skin_assessment/screens/scan_face_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Analysis',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.start,
      routes: AppRoutes.getRoutes(),
    );
  }
}
