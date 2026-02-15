import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/user_configuration.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/usecases/get_device_info.dart';
import '../../domain/usecases/get_user_configuration.dart';
import '../../domain/usecases/get_user_locations.dart';
import '../../domain/usecases/register_device.dart';
import 'user_event.dart';
import 'user_state.dart';

export 'user_event.dart';
export 'user_state.dart';

@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserConfiguration getUserConfiguration;
  final GetDeviceInfo getDeviceInfo;
  final GetUserLocations getUserLocations;
  final RegisterDevice registerDevice;

  UserBloc({
    required this.getUserConfiguration,
    required this.getDeviceInfo,
    required this.getUserLocations,
    required this.registerDevice,
  }) : super(UserInitial()) {
    on<LoadUserInfoEvent>(_onLoadUserInfo);
    on<RegisterDeviceEvent>(_onRegisterDevice);
    on<LoadUserLocationsEvent>(_onLoadUserLocations);
  }

  Future<void> _onLoadUserInfo(
    LoadUserInfoEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    UserConfiguration? config;
    DeviceInfo? deviceInfo;
    List<UserLocation> locations = [];
    String? errorMessage;

    // 1. Get Device Info
    final deviceInfoResult = await getDeviceInfo(NoParams());
    deviceInfoResult.fold(
      (failure) => errorMessage = failure.message,
      (data) => deviceInfo = data,
    );

    if (errorMessage != null) {
      emit(UserError(errorMessage!));
      return;
    }

    // 2. Get Configuration
    final configResult = await getUserConfiguration(NoParams());
    configResult.fold(
      (failure) => errorMessage = failure.message,
      (data) => config = data,
    );

    if (errorMessage != null) {
      emit(UserError(errorMessage!));
      return;
    }

    // 3. Get Locations
    final locationsResult = await getUserLocations(NoParams());
    locationsResult.fold(
      (failure) {
        // We might want to show user info even if locations fail, or treat as error.
        // For now, logging error but proceeding with empty locations if config is loaded
        print('Failed to load locations: ${failure.message}');
      },
      (data) => locations = data,
    );

    if (config != null && deviceInfo != null) {
      emit(UserLoaded(
        configuration: config!,
        deviceInfo: deviceInfo!,
        locations: locations,
      ));
    }
  }

  Future<void> _onRegisterDevice(
    RegisterDeviceEvent event,
    Emitter<UserState> emit,
  ) async {
    // If we are already loaded, we use current info, else we fetch
    String? deviceId;
    String? deviceName;
    String? deviceModel;
    String? versionApp;

    if (state is UserLoaded) {
      final currentState = state as UserLoaded;
      deviceId = currentState.deviceInfo.deviceId;
      deviceModel = currentState.deviceInfo.model;
      deviceName = '$deviceModel ${currentState.deviceInfo.manufacturer}';
      versionApp = currentState.deviceInfo.appVersion;
    } else {
      final deviceInfoResult = await getDeviceInfo(NoParams());
      deviceInfoResult.fold((failure) => null, (info) {
        deviceId = info.deviceId;
        deviceModel = info.model;
        deviceName = '${info.model} ${info.manufacturer}';
        versionApp = info.appVersion;
      });
    }

    if (deviceId != null) {
      emit(DeviceRegistrationLoading());
      final result = await registerDevice(RegisterDeviceParams(
        deviceId: deviceId!,
        deviceName: deviceName!,
        deviceModel: deviceModel!,
        versionApp: versionApp!,
      ));

      result.fold(
        (failure) => emit(DeviceRegistrationFailure(failure.message)),
        (_) => emit(DeviceRegistrationSuccess()),
      );

      // Reload info after registration?
      add(LoadUserInfoEvent());
    } else {
      emit(const DeviceRegistrationFailure(
          "Could not get device info for registration"));
    }
  }

  Future<void> _onLoadUserLocations(
      LoadUserLocationsEvent event, Emitter<UserState> emit) async {
    emit(UserLocationsLoading());
    final result = await getUserLocations(NoParams());
    result.fold(
      (failure) => emit(UserLocationsError(failure.message)),
      (locations) {
        print('Locations loaded: ${locations.length}');
        emit(UserLocationsLoaded(locations: locations));
      },
    );
  }
}

extension UserBlocHelpers on UserBloc {
  String get versionApp {
    if (state is UserLoaded) {
      return (state as UserLoaded).deviceInfo.appVersion;
    }
    return '';
  }

  String get fabricante {
    if (state is UserLoaded) {
      return (state as UserLoaded).deviceInfo.manufacturer;
    }
    return '';
  }

  // Legacy compatibility getters
  List<AllowedWarehouse> get almacenes {
    if (state is UserLoaded) {
      return (state as UserLoaded)
              .configuration
              .result
              ?.result
              ?.allowedWarehouses ??
          [];
    }
    return [];
  }

  List<UserLocation> get ubicaciones {
    // Verificar si el estado es UserLocationsLoaded (cuando se cargan solo ubicaciones)
    if (state is UserLocationsLoaded) {
      return (state as UserLocationsLoaded).locations;
    }
    // Verificar si el estado es UserLoaded (cuando se carga toda la info del usuario)
    if (state is UserLoaded) {
      return (state as UserLoaded).locations;
    }
    return [];
  }

  UserProfile? get configurations {
    if (state is UserLoaded) {
      return (state as UserLoaded).configuration.result?.result;
    }
    return null;
  }

  String get modelo {
    if (state is UserLoaded) {
      return (state as UserLoaded).deviceInfo.model;
    }
    return '';
  }

  String get version {
    if (state is UserLoaded) {
      // Legacy 'version' might reflect OS version or App version. inferring app version or checks
      return (state as UserLoaded).deviceInfo.version;
    }
    return '';
  }

  String get mac {
    if (state is UserLoaded) {
      return (state as UserLoaded).deviceInfo.mac;
    }
    return '';
  }

  String get imei {
    if (state is UserLoaded) {
      return (state as UserLoaded).deviceInfo.imei;
    }
    return '';
  }
}
