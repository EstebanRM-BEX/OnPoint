part of 'auth_bloc.dart';

/// Eventos del AuthBloc
abstract class AuthEvent {}

/// Evento para validar la sesión actual
class ValidateSessionEvent extends AuthEvent {}
