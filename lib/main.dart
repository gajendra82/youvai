import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/themes/app_theme.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:skin_assessment/utils/firebase_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      // For web, check if Firebase is available and ready
      print("Checking Firebase availability on web...");
      
      // Wait a bit longer for Firebase to be ready
      await Future.delayed(Duration(seconds: 3));
      
      // Try to initialize Firebase with retry mechanism
      bool firebaseInitialized = false;
      int retryCount = 0;
      const maxRetries = 5;
      
      while (!firebaseInitialized && retryCount < maxRetries) {
        try {
          // Check if Firebase is available in the browser
          if (await _isFirebaseAvailableInBrowser()) {
            await FirebaseUtils.initializeFirebase();
            FirebaseUtils.printFirebaseStatus();
            await FirebaseUtils.checkFirebaseAuth();
            firebaseInitialized = true;
            print("Firebase initialized successfully on attempt ${retryCount + 1}");
          } else {
            print("Firebase not available in browser, skipping initialization");
            firebaseInitialized = true; // Mark as "handled" to stop retries
          }
        } catch (e) {
          retryCount++;
          print("Firebase initialization attempt $retryCount failed: $e");
          if (retryCount < maxRetries) {
            print("Retrying in 2 seconds...");
            await Future.delayed(Duration(seconds: 2));
          }
        }
      }
      
      if (!firebaseInitialized) {
        print("Firebase initialization failed after $maxRetries attempts. Continuing without Firebase.");
      }
    } else {
      // For mobile platforms
      await FirebaseUtils.initializeFirebase();
      FirebaseUtils.printFirebaseStatus();
      await FirebaseUtils.checkFirebaseAuth();
    }
  } catch (e) {
    print("Firebase initialization error: $e");
    // Continue with app initialization even if Firebase fails
    // This allows the app to run without Firebase if needed
  }
  
  runApp(const MyApp());
}

// Helper function to check if Firebase is available in the browser
Future<bool> _isFirebaseAvailableInBrowser() async {
  try {
    // This will throw an error if Firebase is not available
    await Firebase.apps;
    return true;
  } catch (e) {
    print("Firebase not available in browser: $e");
    return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Skin Analysis',
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.onboard,
        routes: AppRoutes.getRoutes(),
      ),
    );
  }
}
