import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class ProfileUtils {
  /// Check if user profile is complete (has gender and date of birth)
  static Future<bool> isProfileComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');
      
      if (userInfoString != null) {
        final userData = json.decode(userInfoString);
        final user = UserModel.fromJson(userData);
        
        // Check if gender or dateOfBirth is null
        return user.gender != null && user.dateOfBirth != null;
      }
      return false;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  /// Get current user data
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');
      
      if (userInfoString != null) {
        final userData = json.decode(userInfoString);
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Update user data in SharedPreferences
  static Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userInfo', json.encode(userData));
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  /// Update user profile with gender and date of birth
  static Future<void> updateUserProfile(String gender, DateTime dateOfBirth) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserInfoString = prefs.getString('userInfo');
      Map<String, dynamic> updatedUserData = {};
      
      if (currentUserInfoString != null) {
        updatedUserData = Map<String, dynamic>.from(json.decode(currentUserInfoString));
      }
      
      // Update with new gender and date of birth
      updatedUserData['gender'] = gender;
      updatedUserData['date_of_birth'] = dateOfBirth.toIso8601String();
      
      // Save updated user data
      prefs.setString('userInfo', json.encode(updatedUserData));
      print('User profile updated successfully with gender: $gender, dateOfBirth: ${dateOfBirth.toIso8601String()}');
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  /// Clear user data (for logout)
  static Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userInfo');
      await prefs.remove('_token');
      await prefs.remove('isLogin');
      await prefs.remove('isSubscribe');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
}
