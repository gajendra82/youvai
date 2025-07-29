abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({required this.email, required this.password});
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phone;

  RegisterRequested({required this.name, required this.email, required this.password, this.dateOfBirth, this.gender, this.phone});
}
