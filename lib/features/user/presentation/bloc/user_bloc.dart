import 'package:flutter/material.dart';
import 'package:wms_app/core/interfaces/i_device_info_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/user_configuration.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/entities/user_novelty.dart';
import '../../domain/usecases/get_device_info.dart';
import '../../domain/usecases/get_user_configuration.dart';
import '../../domain/usecases/get_user_locations.dart';
import '../../domain/usecases/get_user_novelties.dart';
import '../../domain/usecases/register_device.dart';
import 'user_event.dart';
import 'user_state.dart';
import '../../../../core/utils/prefs/pref_utils.dart';
import '../../../../src/presentation/providers/db/database.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

export 'user_event.dart';
export 'user_state.dart';

@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserConfiguration getUserConfiguration;
  final GetDeviceInfo getDeviceInfo;
  final GetUserLocations getUserLocations;
  final GetUserNovelties getUserNovelties;
  final RegisterDevice registerDevice;

  List<UserLocation> locations = [];
  List<Novedad> novelties = [];

  int locationsCount = 0;
  int noveltiesCount = 0;

  UserConfiguration? userConfiguration;
  DeviceInfo? deviceInfo;

  UserBloc({
    required this.getUserConfiguration,
    required this.getDeviceInfo,
    required this.getUserLocations,
    required this.getUserNovelties,
    required this.registerDevice,
  }) : super(UserInitial()) {
    on<LoadUserInfoEvent>(_onLoadUserInfo);
    on<RegisterDeviceEvent>(_onRegisterDevice);
    on<LoadUserLocationsEvent>(_onLoadUserLocations);
    on<LoadUserNoveltiesEvent>(_onLoadUserNovelties);
    on<LoadInfoDeviceEventUser>(_onLoadInfoDeviceUser);
    on<LoadUserLocationsCountEvent>(_onLoadUserLocationsCount);
    on<LoadUserNoveltiesCountEvent>(_onLoadUserNoveltiesCount);
  }

  Future<void> _onLoadInfoDeviceUser(
    LoadInfoDeviceEventUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    //cargamos la informacion del dispositivo
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    String modelo = androidInfo.model;
    String fabricante = androidInfo.manufacturer;
    String mac = (await getIt<IDeviceInfoService>().getMacAddress()) ??
        ''; // mac del dispositivo
    String imei = (await getIt<IDeviceInfoService>().getImei()) ??
        ''; // imei del dispositivo
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    //REGISTRAMOS LOS DATOS DEL DISPOSITIVO
    await PrefUtils.setMacPDA(mac == 'unknown' ? '' : mac);
    await PrefUtils.setImeiPDA(imei == 'unknown' ? '' : imei);
    await PrefUtils.setModeloPDA(modelo);
    await PrefUtils.setFabricantePDA(fabricante);

    deviceInfo = DeviceInfo(
      model: modelo,
      version: androidInfo.version.release,
      manufacturer: fabricante,
      mac: mac == "02:00:00:00:00:00" ? imei : mac,
      imei: imei,
      appVersion: packageInfo.version,
      deviceId: androidInfo.id,
    );

    emit(DeviceInfoLoaded(deviceInfo: deviceInfo!));
  }

  Future<void> _onLoadUserInfo(
    LoadUserInfoEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    UserConfiguration? config;
    DeviceInfo? deviceInfo;
    List<UserLocation> locations = [];
    List<Novedad> novelties = [];
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

    // 2.1. Save Configuration to Local Database
    if (config != null) {
      try {
        final userId = config!.result?.result?.id;
        if (userId != null) {
          await DataBaseSqlite()
              .configurationsRepository
              .insertConfiguration(config!, userId);
          debugPrint('✅ Configuraciones guardadas en BD local');
        }
      } catch (e) {
        debugPrint('⚠️ Error guardando configuraciones en BD: $e');
      }
    }

    // 3. Get Locations
    // final locationsResult = await getUserLocations(NoParams());
    // locationsResult.fold(
    //   (failure) {
    //     // We might want to show user info even if locations fail, or treat as error.
    //     // For now, logging error but proceeding with empty locations if config is loaded
    //     debugPrint('Failed to load locations: ${failure.message}');
    //   },
    //   (data) => locations = data,
    // );
    add(LoadUserLocationsEvent());

    // 4. Get Novelties
    // final noveltiesResult = await getUserNovelties(NoParams());
    // noveltiesResult.fold(
    //   (failure) {
    //     debugPrint('Failed to load novelties: ${failure.message}');
    //   },
    //   (data) {
    //     novelties = data;
    //     debugPrint('Novelties loaded: ${novelties.length}');
    //   },
    // );
    add(LoadUserNoveltiesEvent());

    if (config != null && deviceInfo != null) {
      userConfiguration = config;
      this.deviceInfo = deviceInfo;

      emit(UserLoaded(
        configuration: userConfiguration!,
        deviceInfo: this.deviceInfo!,
        locations: locations,
        novelties: novelties,
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
        deviceId = info.mac;
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
        (_) {
          emit(DeviceRegistrationSuccess());
        },
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
        this.locations = locations;
        locationsCount = locations.length;
        debugPrint('Locations loaded: ${locations.length}');
        emit(UserLocationsLoaded(locations: locations));
      },
    );
  }

  Future<void> _onLoadUserNovelties(
      LoadUserNoveltiesEvent event, Emitter<UserState> emit) async {
    emit(UserNoveltiesLoading());
    final result = await getUserNovelties(NoParams());
    result.fold(
      (failure) => emit(UserNoveltiesError(failure.message)),
      (novelties) {
        this.novelties = novelties;
        noveltiesCount = novelties.length;
      },
    );
  }

  Future<void> _onLoadUserLocationsCount(
      LoadUserLocationsCountEvent event, Emitter<UserState> emit) async {
    try {
      locationsCount = await DataBaseSqlite().getUbicacionesCount();
      emit(LoadLocationsCountSuccess(locationsCount));
    } catch (e) {
      debugPrint("❌ Error en _onLoadUserLocationsCount: $e");
    }
  }

  Future<void> _onLoadUserNoveltiesCount(
      LoadUserNoveltiesCountEvent event, Emitter<UserState> emit) async {
    try {
      noveltiesCount = await DataBaseSqlite().getNovedadesCount();
      emit(LoadNoveltiesCountSuccess(noveltiesCount));
    } catch (e) {
      debugPrint("❌ Error en _onLoadUserNoveltiesCount: $e");
    }
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

  List<Novedad> get novedades {
    if (state is UserNoveltiesLoaded) {
      return (state as UserNoveltiesLoaded).novelties;
    }
    if (state is UserLoaded) {
      return (state as UserLoaded).novelties;
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
