import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/themes/app_theme.dart';
import 'package:skin_assessment/utils/app_routes.dart';

void main() {
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
