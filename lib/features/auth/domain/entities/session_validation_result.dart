import 'package:equatable/equatable.dart';

/// Resultado de la validación de sesión
class SessionValidationResult extends Equatable {
  final SessionValidationStatus status;

  const SessionValidationResult._(this.status);

  const SessionValidationResult.valid()
      : status = SessionValidationStatus.valid;
  const SessionValidationResult.expired()
      : status = SessionValidationStatus.expired;
  const SessionValidationResult.notLoggedIn()
      : status = SessionValidationStatus.notLoggedIn;

  bool get isValid => status == SessionValidationStatus.valid;
  bool get isExpired => status == SessionValidationStatus.expired;
  bool get isNotLoggedIn => status == SessionValidationStatus.notLoggedIn;

  @override
  List<Object?> get props => [status];
}

enum SessionValidationStatus {
  valid,
  expired,
  notLoggedIn,
}
