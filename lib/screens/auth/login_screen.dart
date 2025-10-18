import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:youv_ai/bloc/auth/auth_bloc.dart';
import 'package:youv_ai/bloc/auth/auth_event.dart';
import 'package:youv_ai/bloc/auth/auth_state.dart';
import 'package:youv_ai/screens/TermAndCondition.dart';
import 'package:youv_ai/utils/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Import your terms & conditions screen

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _mobileController = TextEditingController();
  bool _acceptedTerms = false; // Terms and Conditions checkbox

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> persistLoginInfo({required String message}) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLogin', true);
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
          listener: (context, state) async {
            if (state is AuthAuthenticated) {
              await persistLoginInfo(message: state.message);
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
            if (state is AuthLogout) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLogin');
              await prefs.remove('userInfo');
              await prefs.remove('_token');
              await prefs.remove('isSubscribe');
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.onboard,
                (route) => false,
              );
            }
          },
          builder: (context, state) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo under ScrollView, bigger size
                    Center(
                      child: Image.asset(
                        'assets/logo.png',
                        height: 180, // Increased height
                        width: 180, // Increased width
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 28),
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
                    const SizedBox(height: 40),
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
                    // Terms & Conditions checkbox ONLY
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _acceptedTerms = val ?? false;
                            });
                          },
                        ),
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TermsConditionsScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "I accept the ",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 15,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Terms and Conditions",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                          if (!_acceptedTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Please accept Terms and Conditions to proceed."),
                              ),
                            );
                            return;
                          }
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
                            }, mobilel);
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
                    GoogleSignInButton(
                        acceptedTerms: _acceptedTerms), // Pass acceptedTerms
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showOtpPopup(BuildContext context, void Function(String otp) onOtpSubmit,
      String phoneNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _OtpPopupWidget(
          onOtpSubmit: onOtpSubmit,
          phoneNumber: phoneNumber,
        );
      },
    );
  }
}

/// GoogleSignInButton now checks acceptedTerms before proceeding
class GoogleSignInButton extends StatelessWidget {
  final bool acceptedTerms;
  const GoogleSignInButton({super.key, required this.acceptedTerms});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: state is AuthLoading
              ? null
              : () async {
                  if (!acceptedTerms) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Please accept Terms and Conditions to proceed."),
                      ),
                    );
                    return;
                  }
                  try {
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign-in was cancelled')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign-in failed')),
                    );
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

class _OtpPopupWidget extends StatefulWidget {
  final void Function(String otp) onOtpSubmit;
  final String phoneNumber;

  const _OtpPopupWidget({
    required this.onOtpSubmit,
    required this.phoneNumber,
  });

  @override
  State<_OtpPopupWidget> createState() => _OtpPopupWidgetState();
}

class _OtpPopupWidgetState extends State<_OtpPopupWidget> {
  String enteredOtp = "";
  Timer? _timer;
  int _countdown = 30;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdown = 30;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _resendOtp() {
    if (_canResend) {
      context.read<AuthBloc>().add(SendOtpRequested(phone: widget.phoneNumber));
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP resent successfully!")),
      );
    }
  }

  void _verifyOtp() {
    if (enteredOtp.length == 6) {
      setState(() {
        _isVerifying = true;
      });
      Navigator.of(context).pop();
      widget.onOtpSubmit(enteredOtp);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit OTP")),
      );
    }
  }

  void _cancelOtp() {
    // Stop any loading state and close popup
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          setState(() {
            _isVerifying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Enter OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We sent a 6-digit code to ${widget.phoneNumber}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Pinput(
              length: 6,
              onChanged: (value) => enteredOtp = value,
              onCompleted: (value) {
                enteredOtp = value;
                _verifyOtp();
              },
              defaultPinTheme: PinTheme(
                width: 45,
                height: 55,
                textStyle: const TextStyle(fontSize: 18, color: Colors.black),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 45,
                height: 55,
                textStyle: const TextStyle(fontSize: 18, color: Colors.black),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _canResend ? _resendOtp : null,
                  child: Text(
                    _canResend ? 'Resend OTP' : 'Resend in ${_countdown}s',
                    style: TextStyle(
                      color: _canResend ? primaryColor : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _cancelOtp,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
