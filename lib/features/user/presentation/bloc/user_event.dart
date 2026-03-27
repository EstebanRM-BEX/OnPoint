import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserInfoEvent extends UserEvent {}

class RegisterDeviceEvent extends UserEvent {
  const RegisterDeviceEvent();
}

class LoadUserLocationsEvent extends UserEvent {}

class LoadInfoDeviceEventUser extends LoadUserInfoEvent {}

class LoadUserNoveltiesEvent extends UserEvent {}

class LoadUserLocationsCountEvent extends UserEvent {}

class LoadUserNoveltiesCountEvent extends UserEvent {}
