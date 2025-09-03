import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:skin_assessment/utils/app_routes.dart';

class OnboardScreen extends StatelessWidget {
  const OnboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: PageView(
                    children: [
                      buildOnboardPage(
                        screenHeight,
                        screenWidth,
                        'assets/json/personal_care.json',
                        'Personalized Care',
                        'Recommendations for skincare treatments tailored to your unique skin needs.',
                      ),
                      buildOnboardPage(
                        screenHeight,
                        screenWidth,
                        'assets/json/skin_analysis.json',
                        'Skin Analysis',
                        'Analyze your skin type and get instant feedback.',
                      ),
                      buildOnboardPage(
                        screenHeight,
                        screenWidth,
                        'assets/json/dermlogist.json',
                        'AI Dermatologist',
                        'Get expert advice powered by AI.',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.01),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      dot(0xFF7A7676, 12, 7),
                      const SizedBox(width: 6),
                      dot(0xFFE2E2E2, 7, 7),
                      const SizedBox(width: 6),
                      dot(0xFFE2E2E2, 7, 7),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenHeight * 0.03,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.login,
                              arguments: {'showTab': 'login'},
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text(
                            'Login / Register',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
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

  Widget buildOnboardPage(
    double screenHeight,
    double screenWidth,
    String lottieAsset,
    String title,
    String description,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: screenHeight * 0.38,
          child: Lottie.asset(
            lottieAsset,
            fit: BoxFit.contain,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Color(0xFF444444),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF7A7676),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget dot(int color, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color(color),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
