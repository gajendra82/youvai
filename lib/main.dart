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
      // For web, add a delay to ensure Firebase SDK is loaded
      print("Waiting for Firebase SDK to load...");
      await Future.delayed(Duration(seconds: 2));
      
      // Try to initialize Firebase with retry mechanism
      bool firebaseInitialized = false;
      int retryCount = 0;
      const maxRetries = 3;
      
      while (!firebaseInitialized && retryCount < maxRetries) {
        try {
          await FirebaseUtils.initializeFirebase();
          FirebaseUtils.printFirebaseStatus();
          await FirebaseUtils.checkFirebaseAuth();
          firebaseInitialized = true;
          print("Firebase initialized successfully on attempt ${retryCount + 1}");
        } catch (e) {
          retryCount++;
          print("Firebase initialization attempt $retryCount failed: $e");
          if (retryCount < maxRetries) {
            print("Retrying in 1 second...");
            await Future.delayed(Duration(seconds: 1));
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
