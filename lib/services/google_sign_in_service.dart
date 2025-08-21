import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? '53452910725-6vf2o2pbhjaktliko9ertg454alob398.apps.googleusercontent.com' : null,
  );

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if Firebase is available and working
  static Future<bool> isFirebaseAvailable() async {
    try {
      // Try to access Firebase - this will throw if not available
      await Firebase.apps;
      return true;
    } catch (e) {
      print('Firebase not available: $e');
      return false;
    }
  }

  // Sign in with Google with better error handling
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Check if Firebase is available first
      if (!await isFirebaseAvailable()) {
        throw Exception("Firebase is not available. Please check your internet connection and try again.");
      }

      // Check if user is already signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('Firebase is not available')) {
        throw Exception("Firebase is not available. Please check your internet connection and try again.");
      } else if (e.toString().contains('network')) {
        throw Exception("Network error. Please check your internet connection and try again.");
      } else if (e.toString().contains('popup')) {
        throw Exception("Popup blocked. Please allow popups for this site and try again.");
      } else {
        throw Exception("Sign in failed: ${e.toString()}");
      }
    }
  }

  // Alternative sign-in method that doesn't require Firebase
  static Future<Map<String, dynamic>?> signInWithGoogleWithoutFirebase() async {
    try {
      // Check if user is already signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Get user information directly from Google Sign-In
      return {
        'id': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'serverAuthCode': googleUser.serverAuthCode,
      };
    } catch (e) {
      print('Error signing in with Google (without Firebase): $e');
      throw Exception("Sign in failed: ${e.toString()}");
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (await isFirebaseAvailable()) {
        await _auth.signOut();
      }
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Check if user is signed in
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      print('Error checking sign-in status: $e');
      return false;
    }
  }

  // Get current user
  static User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get Google Sign-In instance
  static GoogleSignIn get googleSignIn => _googleSignIn;

  // Test Google Sign-In availability
  static Future<Map<String, dynamic>> testAvailability() async {
    Map<String, dynamic> result = {
      'firebaseAvailable': false,
      'googleSignInAvailable': false,
      'errors': [],
      'info': []
    };

    try {
      // Test Firebase availability
      result['firebaseAvailable'] = await isFirebaseAvailable();
      result['info'].add('Firebase available: ${result['firebaseAvailable']}');

      // Test Google Sign-In availability
      try {
        await _googleSignIn.isSignedIn();
        result['googleSignInAvailable'] = true;
        result['info'].add('Google Sign-In available: true');
      } catch (e) {
        result['googleSignInAvailable'] = false;
        result['errors'].add('Google Sign-In not available: $e');
      }

    } catch (e) {
      result['errors'].add('Test failed: $e');
    }

    return result;
  }
}
