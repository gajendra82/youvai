import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_event.dart';
import 'package:skin_assessment/bloc/auth/auth_state.dart';
import 'package:skin_assessment/utils/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        builder: (context, state) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0),
            child: Column(
              children: [
                const SizedBox(height: 55),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome Back
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Login to your account
                        Text(
                          "Login to your account",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 60),
                        // Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon:
                                Icon(Icons.email_outlined, color: primaryColor),
                            hintText: "Email",
                            filled: true,
                            fillColor: const Color(0xFFF6F6F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 0),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline_rounded,
                                color: primaryColor),
                            hintText: "Password",
                            filled: true,
                            fillColor: const Color(0xFFF6F6F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 0),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                            ),
                            Text(
                              "Remember me",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                // TODO: Add forgot password logic
                              },
                              child: Text(
                                "Forget Password?",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              // TODO: Add login logic
                              final username = _emailController.text.trim();
                              final password = _passwordController.text.trim();
                              if (username.isNotEmpty &&
                                  password.isNotEmpty &&
                                  state is! AuthLoading) {
                                 context
                                    .read<AuthBloc>()
                                    .add(LoginRequested(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    ));
                                state is AuthAuthenticated
                                    ? Navigator.pushReplacementNamed(
                                        context, AppRoutes.home)
                                    : ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Login failed. Please try again."),
                                        ),
                                      );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please fill in all fields."),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              state is AuthLoading ? "Logging in..." : "Login",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom section
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18.0, top: 8),
                      child: Row(
                        children: const [
                          Expanded(child: Divider(thickness: 1.2)),
                          SizedBox(width: 12),
                          Text(
                            "Or continue with",
                            style: TextStyle(
                              color: Color(0xFFB0A4BA),
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(child: Divider(thickness: 1.2)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Add Google login logic
                        },
                        icon: Image.asset(
                          'assets/google_logo.png',
                          height: 22,
                          width: 22,
                        ),
                        label: const Text(
                          'Login with Google',
                          style: TextStyle(
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
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account yet? ",
                          style: TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // TODO: Navigate to registration
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          child: Text(
                            "do Registration",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
