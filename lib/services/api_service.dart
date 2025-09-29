import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/models/AttractivenessScoreRequest.dart';

class ApiService {
  static const String baseUrl =
      'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api';

  Future<bool> sendAttractivenessScore(
      AttractivenessScoreRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/store-attractiveness-score'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error sending attractiveness score: $e');
      return false;
    }
  }

  // Update user policy acceptance
  static Future<Map<String, dynamic>> updatePolicyAcceptance(
      bool accepted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';

      if (token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/accept-policy'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to update policy acceptance: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating policy acceptance: $e');
    }
  }

  // Check if user has accepted terms and conditions
  static Future<bool> hasAcceptedPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');

      if (userInfoString != null) {
        final userData = json.decode(userInfoString);
        return userData['policy_accept'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking policy acceptance: $e');
      return false;
    }
  }
}
