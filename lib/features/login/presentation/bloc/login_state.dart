part of 'login_bloc.dart';

@immutable
sealed class LoginState {}

/// Initial state
class LoginInitial extends LoginState {}

/// Loading state while authenticating
class LoginLoading extends LoginState {}

/// Success state with user data
class LoginSuccess extends LoginState {
  final User user;
  LoginSuccess(this.user);
}

/// Failure state with error message
class LoginFailure extends LoginState {
  final String message;
  LoginFailure(this.message);
}

/// Password visibility toggled state
class PasswordVisibilityToggled extends LoginState {
  final bool isVisible;
  PasswordVisibilityToggled(this.isVisible);
}
