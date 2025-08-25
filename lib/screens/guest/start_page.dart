import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_event.dart';
import 'package:skin_assessment/bloc/auth/auth_state.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  late final SharedPreferences prefs;
  bool isLogin = false;
  String _username = '';
  void _initPrefs() async {
    print("Initializing preferences");
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isLogin = prefs.getBool('isLogin') ?? false;
      // Try to extract username from userInfo JSON string if available
      final userInfoStr = prefs.getString('userInfo');
      if (userInfoStr != null && userInfoStr.isNotEmpty) {
        try {
          final userInfo = Map<String, dynamic>.from(
            (userInfoStr.startsWith('{'))
                ? (userInfoStr == '{}'
                    ? {}
                    : (userInfoStr.contains('"')
                        ? (userInfoStr.contains('name')
                            ? {
                                'name': userInfoStr
                                    .split('"name":"')[1]
                                    .split('"')[0]
                              }
                            : {})
                        : {}))
                : {},
          );
          _username = userInfo['name'] ?? '';
        } catch (_) {
          _username = '';
        }
      } else {
        _username = '';
      }
    });
    print("Is user logged in: $isLogin");
    print("Username: $_username");
  }

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeb = Theme.of(context).platform == TargetPlatform.fuchsia ||
        identical(
            0, 0.0); // Fallback for web (since kIsWeb is not available here)

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Logout Failed")),
            );
          }
          if (state is AuthLogout) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Logged out successfully")),
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.onboard,
              (route) => false,
            );
          }
        },
        child: Stack(
          children: [
            // Top right Login button

            Positioned(
              top: isWeb ? 24 : 40,
              right: isWeb ? 40 : 20,
              child: TextButton(
                onPressed: () {
                  if (isLogin) {
                    // Show a dropdown menu with logout option
                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        MediaQuery.of(context).size.width - 60, // right
                        isWeb ? 64 : 80, // top
                        20, // left
                        0, // bottom
                      ),
                      items: [
                        PopupMenuItem(
                          child: ListTile(
                            leading:
                                const Icon(Icons.logout, color: Colors.red),
                            title: Text('Logout'),
                            onTap: () async {
                              context.read<AuthBloc>().add(LogoutRequested());
                            },
                          ),
                        ),
                      ],
                    );
                    // Navigate to profile or home
                    // Navigator.pushNamed(context, AppRoutes.profile);
                  } else {
                    // Navigate to login/registration
                    Navigator.pushNamed(context, AppRoutes.login);
                  }
                  // Navigator.pushNamed(context, AppRoutes.onboard);
                },
                child: Text(
                  isLogin ? "Hello, $_username" : 'Login/Registration',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.normal,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated background behind logo
                  SizedBox(
                    width: isWeb ? 400 : 348,
                    height: isWeb ? 400 : 348,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated "snookte" effect
                        // if (!isWeb)
                        //   Positioned.fill(child: AnimatedSnookte()),
                        // Logo image
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/logo.png',
                              width: isWeb ? 200 : 200,
                              height: isWeb ? 200 : 240,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            Positioned(
              bottom: isWeb ? 120 : 90,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 80.0 : 32.0),
                child: Column(
                  children: [
                    Text(
                      'Ready to analyze your skin',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () {
                          // TODO: Start analysis
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              bool accepted = false;
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: const Text('Terms and Conditions'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Please read and accept our Terms and Conditions before proceeding.',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 16),
                                          // Scrollable Terms & Conditions
                                          Container(
                                            constraints: const BoxConstraints(
                                                maxHeight: 260),
                                            child: SingleChildScrollView(
                                              child: Text(
                                                '''
Welcome to Youv.ai (“App”, “we”, “our”, “us”). By using our app, you (“user”, “you”, “your”) agree to the following Terms and Conditions. Please read them carefully before using our services. If you do not agree, you should not use the App.

1. Purpose of the App
- The Youv.ai App provides AI-based skin analysis and related insights for educational and informational purposes only.
- The results, images, or recommendations generated are not medical advice, diagnosis, or treatment.
- Always consult a licensed dermatologist or healthcare professional for any medical concerns.

2. Eligibility
- You must be at least 18 years old (or have parental/guardian consent if under 18) to use this App.
- By using the App, you confirm that all information you provide is accurate and truthful.

3. Use of AI-Generated Content
- All analysis, reports, and visual outputs (including “before/after” simulations) are generated by AI and may not fully reflect actual results.
- The App does not guarantee accuracy of the analysis or results.
- AI-generated outputs should not be considered a substitute for professional medical consultation.

4. User Responsibilities
You agree:
- To use the App for personal and non-commercial purposes only.
- Not to misuse, copy, or resell AI outputs without our written consent.
- To upload only your own images (or images you have the right to use).
- Not to upload offensive, unlawful, or harmful content.

5. Privacy & Data Usage
- We may collect and process personal data (including images) for the purpose of providing AI skin analysis.
- Images uploaded may be temporarily stored and processed by our AI system.
- We do not sell your personal information to third parties.
- Please review our Privacy Policy for detailed information on data handling.

6. Payments & Subscriptions (If Applicable)
- Some features may require a subscription or one-time payment.
- All fees are displayed within the App before purchase.
- Payments are handled securely through third-party payment providers.

7. Disclaimers
- The App and its AI features are provided “as is” and “as available” without any warranties.
- We make no guarantees about accuracy, reliability, or results from using the App.
- We are not responsible for decisions you make based on AI outputs.

8. Limitation of Liability
- To the fullest extent permitted by law, Youv.ai shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use of the App.
- Your sole remedy for dissatisfaction with the App is to discontinue use.

9. Intellectual Property
- All software, logos, trademarks, and AI technology used in the App are owned by or licensed to Youv.ai.
- You may not copy, modify, distribute, or exploit our content without prior permission.

10. Termination
- We may suspend or terminate your access to the App at any time for violating these Terms.
- You may stop using the App at any time by uninstalling it.

11. Changes to Terms
- We may update these Terms from time to time.
- Continued use of the App after changes means you accept the updated Terms.

12. Governing Law
- These Terms shall be governed by and interpreted in accordance with the laws of [Insert Country/State].

13. Contact Us
For questions, support, or complaints, you can reach us at:
support@youv.ai
                                            ''',
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.pushNamed(
                                              context, AppRoutes.skinAnalysis);
                                        },
                                        child: const Text('Accept'),
                                      ),
                                    ],
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        24, 20, 24, 0),
                                    actionsPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    insetPadding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    // Checkbox for acceptance
                                    buttonPadding: EdgeInsets.zero,
                                    // Add checkbox below content
                                    // Use a Column for content + checkbox
                                    // So move checkbox inside content
                                    contentTextStyle:
                                        Theme.of(context).textTheme.bodyMedium,
                                  );
                                },
                              );
                            },
                          );

                          // Remove the direct navigation to skinAnalysis page below
                          return;
                          Navigator.pushNamed(context, AppRoutes.skinAnalysis);
                        },
                        child: const Text(
                          'Start',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Simple animated circles for "snookte" effect
class AnimatedSnookte extends StatefulWidget {
  @override
  State<AnimatedSnookte> createState() => _AnimatedSnookteState();
}

class _AnimatedSnookteState extends State<AnimatedSnookte>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation1 = Tween<double>(begin: 0.7, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _animation2 = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor.withOpacity(0.2);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _animation2.value,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ),
            Transform.scale(
              scale: _animation1.value,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
