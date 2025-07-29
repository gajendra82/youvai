import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await http.post(
        Uri.parse(
            'http://aestheticai.globalspace.in/youvai/youvai_backend/public/api/auth/login'),
        body: {
          'email': event.email,
          'password': event.password,
        },
      );
      print(response.body);
      print(response.statusCode);


      if (response.statusCode == 200) {

        final prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLogin', true);

        // Optionally, store user info from response
        emit(AuthAuthenticated("Login successful!"));
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('data')) {
          print("User info received: ${responseData['data']}");
          prefs.setString('userInfo', json.encode(responseData['data']));
          prefs.setString('_token', responseData['data']['token'] ?? '');

          print("User info stored: ${responseData['data']['token']}");
        } else {
          emit(AuthError('Invalid response format'));
          return;
        }
      } else {
        emit(AuthError('Login failed: ${response.body}'));
        return;
      }
    } catch (e) {
      print("Login error: $e");
      emit(AuthError('Login failed: $e'));
      return;
    }
    print(
        "Login requested with email: ${event.email} and password: ${event.password}");
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    print(
        "Register requested with name: ${event.name}, email: ${event.email}, dateOfBirth: ${event.dateOfBirth}, gender: ${event.gender}, address: ${event.address}");
    var isvalidate = validateRegistrationFields(
      name: event.name,
      email: event.email,
      password: event.password,
      confirmPassword: event
          .password, // Assuming confirmPassword is same as password for simplicity
      // dateOfBirth: event.dateOfBirth?.toIso8601String(),
      // gender: event.gender,
      // address: event.address,
    );
    print("isvalidate: $isvalidate");
    if (!isvalidate['isValid']) {
      emit(AuthError(isvalidate['message']));
      return;
    }

    emit(AuthLoading());
    try {
      // Replace with your actual API endpoint
      final response = await http.post(
        Uri.parse(
            'http://aestheticai.globalspace.in/youvai/youvai_backend/public/api/auth/register'),
        body: {
          'name': event.name,
          'email': event.email,
          'password': event.password,
          'dateOfBirth': event.dateOfBirth?.toIso8601String() ?? '',
          'gender': event.gender ?? '',
          'address': event.address ?? '',
        },
      );
      print(response.body);

      if (response.statusCode == 201) {
        // Registration successful
        emit(AuthAuthenticated("Registration successful!"));
      } else {
        emit(AuthError('Registration failed: ${response.body}'));
        return;
      }
    } catch (e) {
      emit(AuthError('Registration failed: $e'));
      return;
    }
    // Simulate successful registration
  }

  /// Returns a tuple of (isValid, message)
  Map<String, dynamic> validateRegistrationFields({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    // required String dateOfBirth,
    // required String gender,
    // required String address,
  }) {
    if (name.isEmpty ||
            email.isEmpty ||
            password.isEmpty ||
            confirmPassword.isEmpty
        // dateOfBirth.isEmpty ||
        // gender.isEmpty ||
        // address.isEmpty
        ) {
      return {
        'isValid': false,
        'message': 'All fields are required.',
      };
    }
    if (password != confirmPassword) {
      return {
        'isValid': false,
        'message': 'Passwords do not match.',
      };
    }
    // Add more validation as needed (e.g., email format)
    return {
      'isValid': true,
      'message': 'Validation successful.',
    };
  }
}
