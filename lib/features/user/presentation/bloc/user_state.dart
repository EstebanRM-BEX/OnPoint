import 'package:equatable/equatable.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/user_configuration.dart';
import '../../domain/entities/user_location.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final UserConfiguration configuration;
  final DeviceInfo deviceInfo;
  final List<UserLocation> locations;

  const UserLoaded({
    required this.configuration,
    required this.deviceInfo,
    this.locations = const [],
  });

  UserLoaded copyWith({
    UserConfiguration? configuration,
    DeviceInfo? deviceInfo,
    List<UserLocation>? locations,
  }) {
    return UserLoaded(
      configuration: configuration ?? this.configuration,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      locations: locations ?? this.locations,
    );
  }

  @override
  List<Object?> get props => [configuration, deviceInfo, locations];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceRegistrationSuccess extends UserState {}

class DeviceRegistrationFailure extends UserState {
  final String message;
  const DeviceRegistrationFailure(this.message);
}

class DeviceRegistrationLoading extends UserState {}

class UserLocationsLoaded extends UserState {
  final List<UserLocation> locations;

  UserLocationsLoaded({required this.locations});

  @override
  List<Object?> get props => [locations];
}

class UserLocationsLoading extends UserState {}

class UserLocationsError extends UserState {
  final String message;

  UserLocationsError(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceInfoLoaded extends UserState {
  final DeviceInfo deviceInfo;

  const DeviceInfoLoaded({required this.deviceInfo});

  @override
  List<Object?> get props => [deviceInfo];
}

class DeviceInfoLoading extends UserState {}

class DeviceInfoError extends UserState {
  final String message;

  const DeviceInfoError(this.message);

  @override
  List<Object?> get props => [message];
}
