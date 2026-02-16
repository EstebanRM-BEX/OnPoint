part of 'auth_bloc.dart';

/// Estados del AuthBloc
abstract class AuthState {}

/// Estado inicial
class AuthInitial extends AuthState {}

/// Estado de validación en progreso
class AuthValidating extends AuthState {}

/// Estado cuando la sesión es válida
class AuthValid extends AuthState {}

/// Estado cuando la sesión ha expirado
class AuthExpired extends AuthState {}

/// Estado cuando el usuario no está logueado
class AuthNotLoggedIn extends AuthState {}

/// Estado de error
class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
