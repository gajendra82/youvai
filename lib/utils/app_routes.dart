import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/auth/login_screen.dart';
import 'package:skin_assessment/screens/auth/register_screen.dart';
import 'package:skin_assessment/screens/dashboard.dart';
import 'package:skin_assessment/screens/disclaimer_privacy_screen.dart';
import 'package:skin_assessment/screens/guest/onboard_screen.dart';
import 'package:skin_assessment/screens/guest/start_page.dart';
import 'package:skin_assessment/screens/skin_analysis_screen.dart';
// import other screens here

class AppRoutes {
  static const String home = '/start';
  static const String onboard = '/onboard';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String start = '/start';
  static const String skinAnalysis = '/skin_analysis';
  static const String disclaimerPrivacy = '/disclaimer_privacy';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      start: (context) => StartPage(),
      onboard: (context) => OnboardScreen(),
      login: (context) => LoginPage(),
      register: (context) => RegisterPage(),
      skinAnalysis: (context) => SkinAnalysisScreen(),
      dashboard: (context) => DashboardScreen(),
      disclaimerPrivacy: (context) => const DisclaimerPrivacyScreen(),
      // journey: (context) => const JourneyScreen(),
      // profile: (context) => const ProfileScreen(),
      // articles: (context) => const ArticlesScreen(),
    };
  }
}
