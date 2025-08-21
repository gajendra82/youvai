import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

class FirebaseUtils {
  static const FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyAlg92sDvJb8xmuMt8yA9MtjbWrHMWV1oY",
    authDomain: "youvai-56995.firebaseapp.com",
    projectId: "youvai-56995",
    storageBucket: "youvai-56995.appspot.com",
    messagingSenderId: "377693730311",
    appId: "1:377693730311:web:24dfc047db461c18c3dca2",
  );

  static Future<void> initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        print("Initializing Firebase...");
        await Firebase.initializeApp(options: firebaseOptions);
        print("Firebase initialized successfully");
      } else {
        print("Firebase already initialized");
      }
    } catch (e) {
      print("Firebase initialization error: $e");
      
      // For web, try to wait a bit and retry
      if (kIsWeb) {
        print("Waiting before retry...");
        await Future.delayed(Duration(milliseconds: 500));
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(options: firebaseOptions);
            print("Firebase initialized successfully on retry");
          }
        } catch (retryError) {
          print("Firebase retry failed: $retryError");
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  static bool isFirebaseInitialized() {
    return Firebase.apps.isNotEmpty;
  }

  static Future<bool> checkFirebaseAuth() async {
    try {
      if (!isFirebaseInitialized()) {
        print("Firebase not initialized, attempting to initialize...");
        await initializeFirebase();
      }
      
      // Try to get current user to test auth
      final user = FirebaseAuth.instance.currentUser;
      print("Firebase Auth check: ${user != null ? 'User logged in' : 'No user logged in'}");
      return true;
    } catch (e) {
      print("Firebase Auth check failed: $e");
      return false;
    }
  }

  static void printFirebaseStatus() {
    print("Firebase apps count: ${Firebase.apps.length}");
    print("Is web platform: $kIsWeb");
    if (Firebase.apps.isNotEmpty) {
      print("Firebase app name: ${Firebase.app().name}");
    }
  }

  // Method to check if Firebase is ready for use
  static Future<bool> isFirebaseReady() async {
    try {
      if (!isFirebaseInitialized()) {
        return false;
      }
      
      // Try a simple Firebase operation
      await FirebaseAuth.instance.authStateChanges().first;
      return true;
    } catch (e) {
      print("Firebase not ready: $e");
      return false;
    }
  }

  // Method to wait for Firebase to be ready
  static Future<void> waitForFirebase() async {
    int attempts = 0;
    const maxAttempts = 10;
    
    while (attempts < maxAttempts) {
      if (await isFirebaseReady()) {
        print("Firebase is ready");
        return;
      }
      
      attempts++;
      print("Waiting for Firebase to be ready... attempt $attempts");
      await Future.delayed(Duration(milliseconds: 500));
    }
    
    throw Exception("Firebase failed to become ready after $maxAttempts attempts");
  }

  // Method to check if Firebase is available and working
  static Future<bool> isFirebaseAvailable() async {
    try {
      // For web, check if Firebase is available in the browser
      if (kIsWeb) {
        // Try to access Firebase - this will throw if not available
        await Firebase.apps;
        return true;
      } else {
        // For mobile, Firebase should always be available
        return true;
      }
    } catch (e) {
      print("Firebase not available: $e");
      return false;
    }
  }

  // Method to safely initialize Firebase with availability check
  static Future<bool> safeInitializeFirebase() async {
    try {
      if (await isFirebaseAvailable()) {
        await initializeFirebase();
        return true;
      } else {
        print("Firebase not available, skipping initialization");
        return false;
      }
    } catch (e) {
      print("Safe Firebase initialization failed: $e");
      return false;
    }
  }

  // Method to get Firebase status for debugging
  static Map<String, dynamic> getFirebaseStatus() {
    return {
      'isWeb': kIsWeb,
      'appsCount': Firebase.apps.length,
      'isInitialized': isFirebaseInitialized(),
      'appName': Firebase.apps.isNotEmpty ? Firebase.app().name : null,
    };
  }
}
