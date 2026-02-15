part of 'login_bloc.dart';

@immutable
sealed class LoginEvent {}

/// Event triggered when user presses login button
class LoginButtonPressed extends LoginEvent {
  final String email;
  final String password;
  final String database;

  LoginButtonPressed({
    required this.email,
    required this.password,
    required this.database,
  });
}

/// Event to toggle password visibility
class TogglePasswordVisibility extends LoginEvent {}
