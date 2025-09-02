import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_event.dart';
import 'package:skin_assessment/bloc/auth/auth_state.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/user_model.dart';
import '../../widgets/terms_conditions_popup.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  late final SharedPreferences prefs;
  bool isLogin = false;
  String _username = '';
  bool _hasCheckedTerms = false;

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
    
    // Check terms and conditions after initializing preferences
    _checkTermsAndConditions();
  }

  Future<void> _checkTermsAndConditions() async {
    try {
      final userInfoString = prefs.getString('userInfo');
      
      if (userInfoString != null) {
        final userData = json.decode(userInfoString);
        final user = UserModel.fromJson(userData['user']);
        
        // Check if policy_accept is null or false
        print('user.policyAccept: ${user.policyAccept}');
        if (user.policyAccept == null || user.policyAccept == 0) {
          if (mounted) {
            // Wait a bit for the screen to load
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              _showTermsConditionsPopup();
            }
          }
        }
      }
    } catch (e) {
      print('Error checking terms and conditions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _hasCheckedTerms = true;
        });
      }
    }
  }

  void _showTermsConditionsPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TermsConditionsPopup(
          onAccept: (accepted) async {
            try {
              if (accepted) {
                // Call the policy acceptance event
                context.read<AuthBloc>().add(
                  AcceptPolicyRequested(accepted: true),
                );
                
                // Wait for the update to complete
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Close the popup
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              }
            } catch (e) {
              print('Error in terms acceptance: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error accepting terms: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
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
          if (state is PolicyAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
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
                          // Navigate directly to skin analysis
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
