class ServerException implements Exception {
  final String message;
  const ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException(this.message);

  @override
  String toString() => 'SessionExpiredException: $message';
}

class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// El backend rechazó la operación pero ofrece reintentarla forzando una
/// confirmación explícita del usuario (ej. code 202 de create_lote cuando la
/// fecha de vencimiento es anterior a hoy y el permiso lo permite).
class ConfirmationRequiredException implements Exception {
  final String message;
  const ConfirmationRequiredException(this.message);

  @override
  String toString() => 'ConfirmationRequiredException: $message';
}
