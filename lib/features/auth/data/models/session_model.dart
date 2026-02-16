import 'package:wms_app/features/auth/domain/entities/session.dart';

/// Modelo de datos que extiende la entidad Session
class SessionModel extends Session {
  const SessionModel({
    required bool isLoggedIn,
    DateTime? lastActiveTime,
    int? userId,
  }) : super(
          isLoggedIn: isLoggedIn,
          lastActiveTime: lastActiveTime,
          userId: userId,
        );

  /// Crea un SessionModel desde datos de preferencias
  factory SessionModel.fromPrefs({
    required bool isLoggedIn,
    DateTime? lastActiveTime,
    int? userId,
  }) {
    return SessionModel(
      isLoggedIn: isLoggedIn,
      lastActiveTime: lastActiveTime,
      userId: userId,
    );
  }

  /// Convierte el modelo a un mapa (si se necesita persistencia adicional)
  Map<String, dynamic> toJson() => {
        'isLoggedIn': isLoggedIn,
        'lastActiveTime': lastActiveTime?.toIso8601String(),
        'userId': userId,
      };

  /// Crea un SessionModel desde un mapa JSON
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      isLoggedIn: json['isLoggedIn'] as bool,
      lastActiveTime: json['lastActiveTime'] != null
          ? DateTime.parse(json['lastActiveTime'] as String)
          : null,
      userId: json['userId'] as int?,
    );
  }
}
