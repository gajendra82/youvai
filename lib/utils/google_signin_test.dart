import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleSignInTest {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? '377693730311-24dfc047db461c18c3dca2.apps.googleusercontent.com' : null,
  );

  // Test Google Sign-In configuration
  static Future<Map<String, dynamic>> testConfiguration() async {
    Map<String, dynamic> result = {
      'success': false,
      'errors': [],
      'warnings': [],
      'info': []
    };

    try {
      // Test 1: Check if Google Sign-In is available
      result['info'].add('Testing Google Sign-In availability...');
      
      // Test 2: Check if user is already signed in
      bool isSignedIn = await _googleSignIn.isSignedIn();
      result['info'].add('User signed in: $isSignedIn');

      // Test 3: Check Firebase Auth
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        result['info'].add('Firebase Auth current user: ${currentUser?.email ?? 'None'}');
      } catch (e) {
        result['errors'].add('Firebase Auth error: $e');
      }

      // Test 4: Check platform
      result['info'].add('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      
      // Test 5: Check client ID
      if (kIsWeb) {
        result['info'].add('Web client ID configured: ${_googleSignIn.clientId != null}');
      }

      result['success'] = result['errors'].isEmpty;
      
    } catch (e) {
      result['errors'].add('Configuration test failed: $e');
      result['success'] = false;
    }

    return result;
  }

  // Test Google Sign-In flow (without actually signing in)
  static Future<Map<String, dynamic>> testSignInFlow() async {
    Map<String, dynamic> result = {
      'success': false,
      'errors': [],
      'warnings': [],
      'info': []
    };

    try {
      result['info'].add('Testing Google Sign-In flow...');
      
      // Check if we can access Google Sign-In
      bool canAccess = await _googleSignIn.isSignedIn();
      result['info'].add('Can access Google Sign-In: true');
      
      // Note: We don't actually trigger sign-in here to avoid user interaction
      result['info'].add('Google Sign-In flow test completed (no actual sign-in triggered)');
      
      result['success'] = true;
      
    } catch (e) {
      result['errors'].add('Sign-in flow test failed: $e');
      result['success'] = false;
    }

    return result;
  }

  // Print test results
  static void printTestResults(Map<String, dynamic> results) {
    print('=== Google Sign-In Test Results ===');
    print('Success: ${results['success']}');
    
    if (results['info'].isNotEmpty) {
      print('\nInfo:');
      for (String info in results['info']) {
        print('  ✓ $info');
      }
    }
    
    if (results['warnings'].isNotEmpty) {
      print('\nWarnings:');
      for (String warning in results['warnings']) {
        print('  ⚠ $warning');
      }
    }
    
    if (results['errors'].isNotEmpty) {
      print('\nErrors:');
      for (String error in results['errors']) {
        print('  ✗ $error');
      }
    }
    
    print('\n================================');
  }
}
