import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
        await Firebase.initializeApp(options: firebaseOptions);
        print("Firebase initialized successfully");
      } else {
        print("Firebase already initialized");
      }
    } catch (e) {
      print("Firebase initialization error: $e");
      rethrow;
    }
  }

  static bool isFirebaseInitialized() {
    return Firebase.apps.isNotEmpty;
  }

  static Future<bool> checkFirebaseAuth() async {
    try {
      if (!isFirebaseInitialized()) {
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
}
