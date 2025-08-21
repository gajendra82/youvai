import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_event.dart';
import 'package:skin_assessment/bloc/auth/auth_state.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:skin_assessment/utils/firebase_utils.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({Key? key}) : super(key: key);

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  // You should place your asset image path here or use NetworkImage if needed.
  final String illustrationAsset = 'assets/images/skincare_illustration.png';
  // This is a placeholder for the illustration asset.

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkLoginStatus();
  }

  checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLogin = prefs.getBool('isLogin') ?? false;
    if (isLogin) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenHeight = constraints.maxHeight;
            final double screenWidth = constraints.maxWidth;

            return Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: PageController(viewportFraction: 1),
                    onPageChanged: (index) {
                      // For dynamic dots, use a StatefulWidget
                    },
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: screenHeight * 0.38,
                            child: Lottie.asset(
                              'assets/json/personal_care.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.08),
                            child: const Column(
                              children: const [
                                SizedBox(height: 32),
                                Text(
                                  'Personalized Care',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Color(0xFF444444),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'With our advanced algorithms, we can provide recommendations for skincare treatments tailored to your unique skin needs.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF7A7676),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: screenHeight * 0.38,
                            child: Lottie.asset(
                              'assets/json/skin_analysis.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.08),
                            child: const Column(
                              children: [
                                SizedBox(height: 32),
                                Text(
                                  'Skin Analysis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Color(0xFF444444),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Analyze your skin type and get instant feedback to improve your skincare routine.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF7A7676),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: screenHeight * 0.38,
                            child: Lottie.asset(
                              'assets/json/dermlogist.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.08),
                            child: const Column(
                              children: [
                                SizedBox(height: 32),
                                Text(
                                  'AI Dermatologist',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Color(0xFF444444),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Get expert advice powered by AI to help you understand and care for your skin like a dermatologist.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF7A7676),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Dots indicator (static)
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.01),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A7676),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Buttons
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.03),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, AppRoutes.register);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(0, 48),
                              ),
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.login,
                                    arguments: {'fromRoute': '/home'});
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.5,
                                ),
                                minimumSize: const Size(0, 48),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Color(0xFF82608A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // SizedBox(
                      //   width: double.infinity,
                      //   child: OutlinedButton.icon(
                      //     onPressed: () async {
                      //       // Handle Google Login
                      //       try {
                      //         final GoogleAuthProvider googleProvider =
                      //             GoogleAuthProvider();
                      //         await FirebaseAuth.instance
                      //             .signInWithPopup(googleProvider);
                      //         print(FirebaseAuth.instance.currentUser?.email);
                      //         print(FirebaseAuth
                      //             .instance.currentUser?.displayName);
                      //         print(FirebaseAuth.instance.currentUser?.uid);
                      //         print(
                      //             FirebaseAuth.instance.currentUser?.photoURL);
                      //         print(
                      //             FirebaseAuth.instance.currentUser?.photoURL);
                      //         print(
                      //             "Signed in: ${FirebaseAuth.instance.currentUser?.displayName}");
                      //       } catch (e) {
                      //         print("Error signing in on web: $e");
                      //       }
                      //     },
                      //     icon: Image.asset(
                      //       'assets/google_logo.png',
                      //       height: 22,
                      //       width: 22,
                      //     ),
                      //     label: const Text(
                      //       'Login with Google',
                      //       style: TextStyle(
                      //         color: Color(0xFF444444),
                      //         fontWeight: FontWeight.w600,
                      //         fontSize: 16,
                      //       ),
                      //     ),
                      //     style: OutlinedButton.styleFrom(
                      //       padding: const EdgeInsets.symmetric(vertical: 13),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       side: const BorderSide(
                      //         color: Color(0xFFE2E2E2),
                      //         width: 1.2,
                      //       ),
                      //       backgroundColor: Colors.white,
                      //     ),
                      //   ),
                      // ),
                      BlocProvider(
                        create: (_) => AuthBloc(),
                        child: BlocListener<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state is AuthAuthenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${state.message}')),
                              );
                              Navigator.pushReplacementNamed(
                                  context, AppRoutes.start);
                              // Or: Navigator.push(...);
                            } else if (state is AuthError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.error)),
                              );
                            }
                          },
                          child: GoogleSignInButton(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
      return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: state is AuthLoading
                ? null
                : () async {
                    // context.read<AuthBloc>().add(GoogleLoginRequested());
                    try {
                      context.read<AuthBloc>().emit(AuthLoading());
                      
                      // Ensure Firebase is initialized
                      await FirebaseUtils.initializeFirebase();
                      
                      final GoogleAuthProvider googleProvider =
                          GoogleAuthProvider();
                      await FirebaseAuth.instance
                          .signInWithPopup(googleProvider);
                      print(FirebaseAuth.instance.currentUser?.email);
                      print(FirebaseAuth.instance.currentUser?.displayName);
                      print(FirebaseAuth.instance.currentUser?.uid);
                      print(FirebaseAuth.instance.currentUser?.photoURL);
                      print(FirebaseAuth.instance.currentUser?.photoURL);
                      print(
                          "Signed in: ${FirebaseAuth.instance.currentUser?.displayName}");
                      context.read<AuthBloc>().add(
                            GoogleLoginRequested(
                              googleToken:
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                              email: FirebaseAuth.instance.currentUser?.email ??
                                  '',
                              displayName: FirebaseAuth
                                      .instance.currentUser?.displayName ??
                                  '',
                              uid: FirebaseAuth.instance.currentUser?.uid ?? '',
                              photoURL:
                                  FirebaseAuth.instance.currentUser?.photoURL ??
                                      '',
                              phoneNumber: FirebaseAuth
                                      .instance.currentUser?.phoneNumber ??
                                  '',
                            ),
                          );
                    } catch (e) {
                      print("Error signing in on web: $e");
                      // Show error to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sign in failed: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      // Reset loading state
                      context.read<AuthBloc>().emit(AuthInitial());
                    }
                  },
            icon: state is AuthLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Image.asset(
                    'assets/google_logo.png',
                    height: 22,
                    width: 22,
                  ),
            label: Text(
              state is AuthLoading ? "Signing in..." : "Login with Google",
              style: const TextStyle(
                color: Color(0xFF444444),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(
                color: Color(0xFFE2E2E2),
                width: 1.2,
              ),
              backgroundColor: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
