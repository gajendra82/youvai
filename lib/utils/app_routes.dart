import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/dashboard.dart';
import 'package:skin_assessment/screens/guest/start_page.dart';
import 'package:skin_assessment/screens/home_page.dart';
import 'package:skin_assessment/screens/skin_analysis_screen.dart';
// import other screens here

class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String start = '/start';
  static const String skinAnalysis = '/skin_analysis';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) =>  HomeScreen(),
      start: (context) =>  StartPage(),
      skinAnalysis: (context) =>  SkinAnalysisScreen(),
      dashboard: (context) =>  DashboardScreen(),
      // journey: (context) => const JourneyScreen(),
      // profile: (context) => const ProfileScreen(),
      // articles: (context) => const ArticlesScreen(),
    };
  }
}