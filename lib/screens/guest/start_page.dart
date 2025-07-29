import 'package:flutter/material.dart';
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
      body: Stack(
        children: [
          // Top right Login button
          Positioned(
            top: isWeb ? 24 : 40,
            right: isWeb ? 40 : 20,
            child: TextButton(
              onPressed: () {
                if (isLogin) {
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
