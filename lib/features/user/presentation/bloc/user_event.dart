import 'package:equatable/equatable.dart';
import 'package:wms_app/features/login/domain/entities/user.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserInfoEvent extends UserEvent {}

class RegisterDeviceEvent extends UserEvent {
  final User? user;
  final String? password;

  const RegisterDeviceEvent({this.user, this.password});

  @override
  List<Object?> get props => [user, password];
}

class LoadUserLocationsEvent extends UserEvent {}

class LoadInfoDeviceEventUser extends LoadUserInfoEvent {}

class LoadUserNoveltiesEvent extends UserEvent {}

class LoadUserLocationsCountEvent extends UserEvent {}

class LoadUserNoveltiesCountEvent extends UserEvent {}

class LoadWarehousesCountEvent extends UserEvent {}

/// Descargas bajo demanda (botones). Antes se disparaban solas al entrar a la
/// pantalla de usuario (GET ubicaciones y GET picking_novelties).
class DownloadLocationsEvent extends UserEvent {}

class DownloadNoveltiesEvent extends UserEvent {}
