import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/themes/app_theme.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:skin_assessment/utils/firebase_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await FirebaseUtils.initializeFirebase();
    FirebaseUtils.printFirebaseStatus();
    
    // Test Firebase Auth
    await FirebaseUtils.checkFirebaseAuth();
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
