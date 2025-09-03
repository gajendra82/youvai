import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_event.dart';
import 'package:skin_assessment/bloc/auth/auth_state.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _mobileController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: BlocProvider(
        create: (_) => AuthBloc(),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.start,
                (route) => false,
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error)));
            }
            if (state is AuthMessage) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 55),
                  Text(
                    "Login / Register",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Continue with mobile OTP or Google",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.phone_android, color: primaryColor),
                      hintText: "Phone Number",
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
                        final mobilel = _mobileController.text.trim();
                        if (mobilel.isNotEmpty) {
                          context.read<AuthBloc>().add(
                                SendOtpRequested(phone: mobilel),
                              );
                          showOtpPopup(context, (otp) {
                            context.read<AuthBloc>().add(
                                  VerifyLoginMobile(
                                    name: "",
                                    email: "",
                                    phone: mobilel,
                                    password: "",
                                    otp: otp,
                                  ),
                                );
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter mobile number."),
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
                        state is AuthLoading
                            ? "Processing..."
                            : "Login / Register with OTP",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
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
                  const SizedBox(height: 18),
                  GoogleSignInButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showOtpPopup(
      BuildContext context, void Function(String otp) onOtpSubmit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String enteredOtp = "";
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Enter OTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Pinput(
                length: 6,
                onChanged: (value) => enteredOtp = value,
                onCompleted: (value) => enteredOtp = value,
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 60,
                  textStyle: const TextStyle(fontSize: 20, color: Colors.black),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOtpSubmit(enteredOtp);
                },
                child: const Text('Verify'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: state is AuthLoading
              ? null
              : () async {
                  try {
                    context.read<AuthBloc>().emit(AuthLoading());
                    final GoogleAuthProvider googleProvider =
                        GoogleAuthProvider();
                    final userCredential = await FirebaseAuth.instance
                        .signInWithPopup(googleProvider);

                    if (userCredential.user != null) {
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
                    } else {
                      context
                          .read<AuthBloc>()
                          .emit(AuthError('Sign-in was cancelled'));
                    }
                  } catch (e) {
                    context.read<AuthBloc>().emit(AuthError('Sign-in failed'));
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
            state is AuthLoading
                ? "Signing in..."
                : "Login/Register with Google",
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
    });
  }
}
