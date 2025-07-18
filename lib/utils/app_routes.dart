import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/dashboard.dart';
import 'package:skin_assessment/screens/home_page.dart';
// import other screens here

class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String articles = '/articles';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) =>  HomeScreen(),
      dashboard: (context) =>  DashboardScreen(),
      // journey: (context) => const JourneyScreen(),
      // profile: (context) => const ProfileScreen(),
      // articles: (context) => const ArticlesScreen(),
    };
  }
}