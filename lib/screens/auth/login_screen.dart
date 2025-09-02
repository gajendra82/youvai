import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_event.dart';
import 'package:skin_assessment/bloc/auth/auth_state.dart';
import 'package:skin_assessment/screens/guest/onboard_screen.dart';
import 'package:skin_assessment/utils/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  String fromRoute = '/'; // Default to splash/init

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey('fromRoute')) {
      fromRoute = args['fromRoute'];
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
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
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            print("User logged in successfully");
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.start,
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error)));
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
                        // Password
                        // TextField(
                        //   controller: _passwordController,
                        //   obscureText: true,
                        //   decoration: InputDecoration(
                        //     prefixIcon: Icon(Icons.lock_outline_rounded,
                        //         color: primaryColor),
                        //     hintText: "Password",
                        //     filled: true,
                        //     fillColor: const Color(0xFFF6F6F6),
                        //     border: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(10),
                        //       borderSide: BorderSide.none,
                        //     ),
                        //     contentPadding: const EdgeInsets.symmetric(
                        //         vertical: 18, horizontal: 0),
                        //   ),
                        // ),
                        // const SizedBox(height: 10),
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
                              final mobilel = _mobileController.text.trim();
                              // final password = _passwordController.text.trim();
                              if (state is AuthLoading) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Logging in... Please wait."),
                                  ),
                                );
                                return;
                              }
                              if (mobilel.isNotEmpty) {
                                context.read<AuthBloc>().add(
                                      SendOtpRequested(
                                          phone: _mobileController.text),
                                    );
                                showOtpPopup(context, (otp) {
                                  context
                                      .read<AuthBloc>()
                                      .add(VerifyLoginMobile(
                                        name: "",
                                        email: "",
                                        phone: _mobileController.text,
                                        password: "",
                                        otp: otp,
                                      ));
                                });
                                // if (state is AuthAuthenticated) {
                                //   print("User logged in successfully");
                                //   // if (fromRoute == '/skin_analysis') {
                                //   //   // ✅ Just pop back
                                //   //   Navigator.pop(context);
                                //   // } else {
                                //   // ✅ Navigate to home
                                //   Navigator.pushNamedAndRemoveUntil(
                                //     context,
                                //     AppRoutes.home,
                                //     (route) => false,
                                //   );
                                // }
                                // }
                                // else {
                                //   ScaffoldMessenger.of(context).showSnackBar(
                                //     const SnackBar(
                                //       content: Text(
                                //           "Login failed. Please try again."),
                                //     ),
                                //   );
                                // }
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
                // Column(
                //   children: [
                //     Padding(
                //       padding: const EdgeInsets.only(bottom: 18.0, top: 8),
                //       child: Row(
                //         children: const [
                //           Expanded(child: Divider(thickness: 1.2)),
                //           SizedBox(width: 12),
                //           Text(
                //             "Or continue with",
                //             style: TextStyle(
                //               color: Color(0xFFB0A4BA),
                //               fontSize: 13,
                //             ),
                //           ),
                //           SizedBox(width: 12),
                //           Expanded(child: Divider(thickness: 1.2)),
                //         ],
                //       ),
                //     ),
                //     SizedBox(
                //       width: double.infinity,
                //       child: OutlinedButton.icon(
                //         onPressed: () {
                //           BlocProvider(
                //             create: (_) => AuthBloc(),
                //             child: BlocListener<AuthBloc, AuthState>(
                //               listener: (context, state) {
                //                 if (state is AuthAuthenticated) {
                //                   ScaffoldMessenger.of(context).showSnackBar(
                //                     SnackBar(content: Text('${state.message}')),
                //                   );
                               
                //                     () async {
                //                       final prefs = await SharedPreferences.getInstance();
                //                         String? gender;
                //                         String? dob;
                //                         final userId = prefs.getString('userId'); 
                //                         final userInfoString = prefs.getString('userInfo');
                //                         if (userInfoString != null) {
                //                           final userInfo = jsonDecode(userInfoString);
                //                           gender = userInfo['gender'] as String?;
                //                           dob = userInfo['dob'] as String?;
                //                         } else {
                //                         gender = prefs.getString('gender');
                //                         dob = prefs.getString('dob');
                //                         }

                //                       if (gender == null || dob == null) {
                //                         // Show popup to get gender and dob
                //                         await showDialog(
                //                           context: context,
                //                           barrierDismissible: false,
                //                           builder: (BuildContext context) {
                //                             String selectedGender = '';
                //                             String selectedDob = '';
                //                             return AlertDialog(
                //                               title: const Text('Complete Profile'),
                //                               content: StatefulBuilder(
                //                                 builder: (context, setState) {
                //                                   return Column(
                //                                     mainAxisSize: MainAxisSize.min,
                //                                     children: [
                //                                       DropdownButtonFormField<String>(
                //                                         value: selectedGender.isEmpty ? null : selectedGender,
                //                                         items: ['Male', 'Female', 'Other']
                //                                             .map((g) => DropdownMenuItem(
                //                                                   value: g,
                //                                                   child: Text(g),
                //                                                 ))
                //                                             .toList(),
                //                                         onChanged: (val) {
                //                                           setState(() {
                //                                             selectedGender = val ?? '';
                //                                           });
                //                                         },
                //                                         decoration: const InputDecoration(
                //                                           labelText: 'Gender',
                //                                         ),
                //                                       ),
                //                                       TextField(
                //                                         readOnly: true,
                //                                         decoration: InputDecoration(
                //                                           labelText: 'Date of Birth',
                //                                           hintText: selectedDob.isEmpty ? 'Select DOB' : selectedDob,
                //                                         ),
                //                                         onTap: () async {
                //                                           final picked = await showDatePicker(
                //                                             context: context,
                //                                             initialDate: DateTime(2000),
                //                                             firstDate: DateTime(1900),
                //                                             lastDate: DateTime.now(),
                //                                           );
                //                                           if (picked != null) {
                //                                             setState(() {
                //                                               selectedDob = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                //                                             });
                //                                           }
                //                                         },
                //                                       ),
                //                                     ],
                //                                   );
                //                                 },
                //                               ),
                //                               actions: [
                //                                 TextButton(
                //                                   onPressed: () {
                //                                     if (selectedGender.isNotEmpty && selectedDob.isNotEmpty) {
                //                                       gender = selectedGender;
                //                                       dob = selectedDob;
                //                                       Navigator.of(context).pop();
                //                                     }
                //                                   },
                //                                   child: const Text('Submit'),
                //                                 ),
                //                               ],
                //                             );
                //                           },
                //                         );

                //                         // Save to SharedPreferences
                //                         if (gender != null && dob != null) {
                //                           await prefs.setString('userInfo', jsonEncode({
                //                             'gender': gender,
                //                             'dob': dob,
                //                           }));

                //                           // Profile update will be handled by ProfileCompletionChecker widget
                //                         }
                //                       }
                //                     }();

                //                   // Profile completion check will be handled by ProfileCompletionChecker widget
                //                   Navigator.pushReplacementNamed(
                //                       context, AppRoutes.start);

                //                   // Or: Navigator.push(...);
                //                 } else if (state is AuthError) {
                //                   ScaffoldMessenger.of(context).showSnackBar(
                //                     SnackBar(content: Text(state.error)),
                //                   );
                //                 }
                //               },
                //               child: GoogleSignInButton(),
                //             ),
                //           );
                //         },
                //         icon: Image.asset(
                //           'assets/google_logo.png',
                //           height: 22,
                //           width: 22,
                //         ),
                //         label: const Text(
                //           'Login with Google',
                //           style: TextStyle(
                //             color: Color(0xFF444444),
                //             fontWeight: FontWeight.w600,
                //             fontSize: 16,
                //           ),
                //         ),
                //         style: OutlinedButton.styleFrom(
                //           padding: const EdgeInsets.symmetric(vertical: 13),
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //           side: const BorderSide(
                //             color: Color(0xFFE2E2E2),
                //             width: 1.2,
                //           ),
                //           backgroundColor: Colors.white,
                //         ),
                //       ),
                //     ),
                //     const SizedBox(height: 18),
                //     Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         const Text(
                //           "Don't have an account yet? ",
                //           style: TextStyle(
                //             color: Color(0xFF444444),
                //             fontSize: 14,
                //           ),
                //         ),
                //         GestureDetector(
                //           onTap: () {
                //             // TODO: Navigate to registration
                //             Navigator.pushNamed(context, AppRoutes.register);
                //           },
                //           child: Text(
                //             "do Registration",
                //             style: TextStyle(
                //               color: primaryColor,
                //               fontWeight: FontWeight.bold,
                //               fontSize: 14,
                //             ),
                //           ),
                //         ),
                //       ],
                //     ),
                //     const SizedBox(height: 16),
                //   ],
                // ),
              
              ],
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
