import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../models/user_model.dart';
import 'profile_update_popup.dart';
import 'terms_conditions_popup.dart';

class ProfileCompletionChecker extends StatefulWidget {
  final Widget child;
  final bool showPopup;

  const ProfileCompletionChecker({
    Key? key,
    required this.child,
    this.showPopup = true,
  }) : super(key: key);

  @override
  State<ProfileCompletionChecker> createState() => _ProfileCompletionCheckerState();
}

class _ProfileCompletionCheckerState extends State<ProfileCompletionChecker> {
  bool _hasCheckedProfile = false;
  bool _isPopupShowing = false;

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');
      
      if (userInfoString != null) {
        final userData = json.decode(userInfoString);
        print('userData: $userData');
        final user = UserModel.fromJson(userData);
        
        // First check if policy_accept is null or false
        print('user.policyAccept: ${user.policyAccept}');
        if (user.policyAccept == null || user.policyAccept == false) {
          if (widget.showPopup && mounted) {
            // Wait a bit for the screen to load
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              _showTermsConditionsPopup();
              return; // Don't check other profile fields until terms are accepted
            }
          }
        }
        
        // Check if gender or dateOfBirth is null
        print('user.gender: ${user.gender}');
        print('user.dateOfBirth: ${user.dateOfBirth}');
        if (user.gender == null || user.dateOfBirth == null) {
          if (widget.showPopup && mounted) {
            // Wait a bit for the screen to load
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              _showProfileUpdatePopup();
            }
          }
        }
      } else {
        print('No user info found in SharedPreferences');
      }
    } catch (e) {
      print('Error checking profile completion: $e');
      // Show error to user if there's a critical error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _hasCheckedProfile = true;
        });
      }
    }
  }

  void _showTermsConditionsPopup() {
    if (_isPopupShowing) return; // Prevent multiple popups
    
    setState(() {
      _isPopupShowing = true;
    });

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
                
                // Check profile completion again after terms acceptance
                await _checkProfileCompletion();
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
    ).then((_) {
      setState(() {
        _isPopupShowing = false;
      });
    });
  }

  void _showProfileUpdatePopup() {
    if (_isPopupShowing) return; // Prevent multiple popups
    
    setState(() {
      _isPopupShowing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProfileUpdatePopup(
          onUpdate: (gender, dateOfBirth) async {
            try {
              // Call the update event
              context.read<AuthBloc>().add(
                UpdateProfileRequested(
                  gender: gender,
                  dateOfBirth: dateOfBirth,
                ),
              );
              
              // Wait for the update to complete
              await Future.delayed(const Duration(milliseconds: 500));
               context.read<AuthBloc>().stream.listen((state) async{
                if (state is AuthProfileLoaded) {
                  // Check if profile is now complete
                  final isComplete = await _isProfileComplete();
                  print('Profile completion check: $isComplete');
                  
                  if (isComplete) {
                    // Close the popup
                    // if (mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    // }
                  }
                }
              });
              // Check if profile is now complete
              // final isComplete = await _isProfileComplete();
              // print('Profile completion check: $isComplete');
              
              // if (isComplete) {
              //   // Close the popup
              //   if (mounted && Navigator.of(context).canPop()) {
              //     Navigator.of(context).pop();
              //   }
                
              //   // Show success message
              //   if (mounted) {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(
              //         content: Text('Profile updated successfully!'),
              //         backgroundColor: Colors.green,
              //       ),
              //     );
              //   }
                
              //   setState(() {
              //     _isPopupShowing = false;
              //   });
              // } else {
              //   // If still not complete, show error
              //   if (mounted) {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(
              //         content: Text('Profile update failed. Please try again.'),
              //         backgroundColor: Colors.red,
              //       ),
              //     );
              //   }
              // }
            } catch (e) {
              print('Error in profile update: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating profile: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    ).then((_) {
      setState(() {
        _isPopupShowing = false;
      });
    });
  }

  Future<bool> _isProfileComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');
      
      if (userInfoString != null) {
        final userData = json.decode(userInfoString);
        final user = UserModel.fromJson(userData);
        
        return user.gender != null && user.dateOfBirth != null;
      }
      return false;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError && _isPopupShowing) {
          // Show error message if popup is showing
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is PolicyAccepted) {
          // Show success message for policy acceptance
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: widget.child,
    );
  }
}
