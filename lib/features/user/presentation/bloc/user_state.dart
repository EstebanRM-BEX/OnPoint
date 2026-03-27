import 'package:equatable/equatable.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/user_configuration.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/entities/user_novelty.dart';

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
  final List<Novedad> novelties;

  const UserLoaded({
    required this.configuration,
    required this.deviceInfo,
    this.locations = const [],
    this.novelties = const [],
  });

  UserLoaded copyWith({
    UserConfiguration? configuration,
    DeviceInfo? deviceInfo,
    List<UserLocation>? locations,
    List<Novedad>? novelties,
  }) {
    return UserLoaded(
      configuration: configuration ?? this.configuration,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      locations: locations ?? this.locations,
      novelties: novelties ?? this.novelties,
    );
  }

  @override
  List<Object?> get props => [configuration, deviceInfo, locations, novelties];
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

  const UserLocationsError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserNoveltiesLoaded extends UserState {
  final List<Novedad> novelties;

  const UserNoveltiesLoaded({required this.novelties});

  @override
  List<Object?> get props => [novelties];
}

class UserNoveltiesLoading extends UserState {}

class UserNoveltiesError extends UserState {
  final String message;
  const UserNoveltiesError(this.message);
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

class LoadLocationsCountSuccess extends UserState {
  final int count;
  LoadLocationsCountSuccess(this.count);

  @override
  List<Object?> get props => [count];
}

class LoadNoveltiesCountSuccess extends UserState {
  final int count;
  LoadNoveltiesCountSuccess(this.count);

  @override
  List<Object?> get props => [count];
}
