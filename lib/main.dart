import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/themes/app_theme.dart';
import 'package:skin_assessment/utils/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyAlg92sDvJb8xmuMt8yA9MtjbWrHMWV1oY",
        authDomain: "youvai-56995.firebaseapp.com",
        projectId: "project-377693730311",
        storageBucket: "youvai-56995.appspot.app",
        messagingSenderId: "377693730311",
        appId: "1:377693730311:web:24dfc047db461c18c3dca2",
      ),
    );
  } catch (e) {
    print("Firebase initialization error: $e");
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
