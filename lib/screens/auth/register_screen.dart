import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_event.dart';
import 'package:skin_assessment/bloc/auth/auth_state.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers for the form fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isMobileVerified = false;
  // For image picker placeholder
  // Implement your own image pick logic
  String? _profileImagePath;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purpleColor = Theme.of(context).primaryColor;

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
            Navigator.pushNamedAndRemoveUntil(
                context, '/start', (route) => false); // go back to login
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 36),
                  Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: purpleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Create your new account",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final ImagePicker _picker = ImagePicker();
                        final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            _profileImagePath = image.path;
                          });
                        }
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withOpacity(0.10),
                          border: Border.all(
                            color: Colors.green,
                            width: 3,
                          ),
                        ),
                        child: Center(
                            child:
                                //  _profileImagePath == null
                                //     ?
                                Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 48,
                          color: Colors.green,
                        )
                            // : ClipOval(
                            //   child: Image.file(
                            //     File(_profileImagePath!),
                            //     width: 110,
                            //     height: 110,
                            //     fit: BoxFit.cover,
                            //   ),
                            // ),
                            ),
                      ),
                    ),
                  ),
                  // Add Photo Circle
                  // Center(
                  //   child: GestureDetector(
                  //     onTap: () async {
                  //       // TODO: Add image picker logic

                  //       final ImagePicker _picker = ImagePicker();
                  //       final XFile? image = await _picker.pickImage(
                  //           source: ImageSource.gallery);
                  //       if (image != null) {
                  //         setState(() {
                  //           _profileImagePath = image.path;
                  //         });
                  //       }
                  //     },
                  //     child: Container(
                  //       width: 200,
                  //       height: 200,
                  //       decoration: BoxDecoration(
                  //         shape: BoxShape.circle,
                  //         color: purpleColor.withOpacity(0.10),
                  //         border: Border.all(
                  //           color: purpleColor,
                  //           width: 3,
                  //         ),
                  //       ),
                  //       child: Center(
                  //         child: Column(
                  //           mainAxisAlignment: MainAxisAlignment.center,
                  //           children: [
                  //             Icon(
                  //               Icons.add_a_photo_rounded,
                  //               size: 38,
                  //               color: purpleColor,
                  //             ),
                  //             const SizedBox(height: 2),
                  //             Text(
                  //               "Add Photo",
                  //               style: TextStyle(
                  //                 color: purpleColor,
                  //                 fontWeight: FontWeight.w600,
                  //                 fontSize: 14,
                  //               ),
                  //             )
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 28),
                  // Username
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          color: purpleColor),
                      hintText: "Username *",
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
                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.email_outlined, color: purpleColor),
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
                  // Mobile Number
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.phone_android, color: purpleColor),
                      hintText: "Mobile Number *",
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

                  // Date of Birth
                  TextField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000, 1, 1),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        _dobController.text =
                            "${picked.toLocal()}".split(' ')[0];
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.cake_outlined, color: purpleColor),
                      hintText: "Date of Birth",
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

                  // const SizedBox(height: 16),
                  // // Password
                  // TextField(
                  //   controller: _passwordController,
                  //   obscureText: !_isPasswordVisible,
                  //   decoration: InputDecoration(
                  //     prefixIcon:
                  //         Icon(Icons.lock_outline_rounded, color: purpleColor),
                  //     hintText: "Password *",
                  //     filled: true,
                  //     fillColor: const Color(0xFFF6F6F6),
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //       borderSide: BorderSide.none,
                  //     ),
                  //     contentPadding: const EdgeInsets.symmetric(
                  //         vertical: 18, horizontal: 0),
                  //     suffixIcon: IconButton(
                  //       icon: Icon(
                  //         _isPasswordVisible
                  //             ? Icons.visibility
                  //             : Icons.visibility_off,
                  //         color: purpleColor,
                  //       ),
                  //       onPressed: () {
                  //         setState(() {
                  //           _isPasswordVisible = !_isPasswordVisible;
                  //         });
                  //       },
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 16),
                  // Confirm Password
                  // TextField(
                  //   controller: _confirmPasswordController,
                  //   obscureText: true,
                  //   decoration: InputDecoration(
                  //     prefixIcon:
                  //         Icon(Icons.lock_outline_rounded, color: purpleColor),
                  //     hintText: "Confirm password",
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
                  // const SizedBox(height: 16),
                  // Date of Birth
                  // TextField(
                  //   controller: _dobController,
                  //   readOnly: true,
                  //   onTap: () async {
                  //     DateTime? picked = await showDatePicker(
                  //       context: context,
                  //       initialDate: DateTime(2000, 1, 1),
                  //       firstDate: DateTime(1900),
                  //       lastDate: DateTime.now(),
                  //     );
                  //     if (picked != null) {
                  //       _dobController.text =
                  //           "${picked.toLocal()}".split(' ')[0];
                  //     }
                  //   },
                  //   decoration: InputDecoration(
                  //     prefixIcon: Icon(Icons.cake_outlined, color: purpleColor),
                  //     hintText: "Date of Birth",
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
                  // const SizedBox(height: 30),
                  // Register Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (state is AuthLoading) return;
                        // Validate the form fields
                        if (_usernameController.text.isEmpty ||
                            _mobileController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Please fill all required fields"),
                            ),
                          );
                          return;
                        }
                        // If mobile number is not verified, show OTP popup
                        context.read<AuthBloc>().add(
                              SendOtpRequested(phone: _mobileController.text),
                            );
                        showOtpPopup(context, (otp) {
                          context.read<AuthBloc>().add(VerifyLoginMobile(
                                name: _usernameController.text,
                                email: _emailController.text,
                                phone: _mobileController.text,
                                password: _passwordController.text,
                                otp: otp,
                              ));
                        });
                        // if (!_isMobileVerified) return;
                        // print("Register button pressed");
                        // if (state is AuthLoading) return;
                        // context.read<AuthBloc>().add(RegisterRequested(
                        //       name: _usernameController.text,
                        //       email: _emailController.text,
                        //       password: _passwordController.text,
                        //       dateOfBirth:
                        //           DateTime.tryParse(_dobController.text),
                        //       gender: _genderController.text,
                        //       phone: _mobileController.text,
                        //     ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        state is AuthLoading ? "Registering..." : "Register",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Terms Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: const TextStyle(
                          color: Color(0xFFB0A4BA),
                          fontSize: 13,
                        ),
                        children: [
                          const TextSpan(
                              text: "By continuing, you agree to our "),
                          TextSpan(
                            text: "Terms of Service",
                            style: const TextStyle(
                              color: Color(0xFF5B4D9E),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                            // TODO: Add gesture recognizer for link
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy.",
                            style: const TextStyle(
                              color: Color(0xFF5B4D9E),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
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
