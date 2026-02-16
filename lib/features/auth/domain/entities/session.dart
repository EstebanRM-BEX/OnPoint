import 'package:equatable/equatable.dart';

/// Entidad que representa una sesión de usuario
class Session extends Equatable {
  final bool isLoggedIn;
  final DateTime? lastActiveTime;
  final int? userId;

  const Session({
    required this.isLoggedIn,
    this.lastActiveTime,
    this.userId,
  });

  /// Verifica si la sesión ha expirado (más de 1 hora de inactividad)
  bool isExpired() {
    if (lastActiveTime == null) return false;
    final difference = DateTime.now().difference(lastActiveTime!);
    return difference >= const Duration(hours: 1);
  }

  @override
  List<Object?> get props => [isLoggedIn, lastActiveTime, userId];
}
