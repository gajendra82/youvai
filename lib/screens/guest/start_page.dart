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
  SharedPreferences? prefs;
  bool isLogin = false;
  String _username = '';
  bool _hasCheckedTerms = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStateAndInitPrefs();
  }

  Future<void> _checkLoginStateAndInitPrefs() async {
    prefs = await SharedPreferences.getInstance();
    final login = prefs?.getBool('isLogin') ?? false;
    if (!login) {
      // If not logged in, navigate to login page.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return;
    }
    // If logged in, continue initialization
    String username = '';
    final userInfoStr = prefs?.getString('userInfo');
    if (userInfoStr != null && userInfoStr.isNotEmpty) {
      try {
        final userInfo = json.decode(userInfoStr);
        if (userInfo is Map && userInfo.containsKey('user')) {
          username = userInfo['user']['name'] ?? '';
        } else if (userInfo is Map && userInfo.containsKey('name')) {
          username = userInfo['name'] ?? '';
        }
      } catch (_) {
        username = '';
      }
    }
    setState(() {
      isLogin = login;
      _username = username;
    });
    _checkTermsAndConditions();
  }

  Future<void> _checkTermsAndConditions() async {
    try {
      final userInfoString = prefs?.getString('userInfo');
      if (userInfoString != null) {
        final userData = json.decode(userInfoString);
        final user = UserModel.fromJson(userData['user'] ?? userData);
        if (user.policyAccept == null || user.policyAccept == 0) {
          if (mounted) {
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
                context.read<AuthBloc>().add(
                      AcceptPolicyRequested(accepted: true),
                    );
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              }
            } catch (e) {
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

  Future<void> _logout() async {
    if (prefs != null) {
      await prefs!.setBool('isLogin', false);
      await prefs!.remove('userInfo');
      await prefs!.remove('_token');
    }
    context.read<AuthBloc>().add(LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeb = Theme.of(context).platform == TargetPlatform.fuchsia ||
        identical(0, 0.0);

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
                context, AppRoutes.onboard, (route) => false);
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
            Positioned(
              top: isWeb ? 24 : 40,
              right: isWeb ? 40 : 20,
              child: TextButton(
                onPressed: () {
                  if (isLogin) {
                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        MediaQuery.of(context).size.width - 60,
                        isWeb ? 64 : 80,
                        20,
                        0,
                      ),
                      items: [
                        PopupMenuItem(
                          child: ListTile(
                            leading:
                                const Icon(Icons.logout, color: Colors.red),
                            title: Text('Logout'),
                            onTap: () async {
                              Navigator.of(context).pop(); // close menu
                              await _logout();
                            },
                          ),
                        ),
                      ],
                    );
                  } else {
                    Navigator.pushNamed(context, AppRoutes.login);
                  }
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
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: isWeb ? 400 : 348,
                    height: isWeb ? 400 : 348,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
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
