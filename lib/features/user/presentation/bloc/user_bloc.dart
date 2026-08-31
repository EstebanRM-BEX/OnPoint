import 'package:flutter/material.dart';
import 'package:wms_app/core/interfaces/i_device_info_service.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/login/domain/usecases/save_user_session.dart';
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
  final SaveUserSession saveUserSession;

  List<UserLocation> locations = [];
  List<Novedad> novelties = [];

  int locationsCount = 0;
  int noveltiesCount = 0;
  int warehousesCount = 0;

  UserConfiguration? userConfiguration;
  DeviceInfo? deviceInfo;

  final NetworkInfo _networkInfo = getIt<NetworkInfo>();

  UserBloc({
    required this.getUserConfiguration,
    required this.getDeviceInfo,
    required this.getUserLocations,
    required this.getUserNovelties,
    required this.registerDevice,
    required this.saveUserSession,
  }) : super(UserInitial()) {
    on<LoadUserInfoEvent>(_onLoadUserInfo);
    on<RegisterDeviceEvent>(_onRegisterDevice);
    on<LoadUserLocationsEvent>(_onLoadUserLocations);
    on<LoadUserNoveltiesEvent>(_onLoadUserNovelties);
    on<LoadInfoDeviceEventUser>(_onLoadInfoDeviceUser);
    on<LoadUserLocationsCountEvent>(_onLoadUserLocationsCount);
    on<LoadUserNoveltiesCountEvent>(_onLoadUserNoveltiesCount);
    on<LoadWarehousesCountEvent>(_onLoadWarehousesCount);
    on<DownloadLocationsEvent>(_onDownloadLocations);
    on<DownloadNoveltiesEvent>(_onDownloadNovelties);
  }

  /// Descarga bajo demanda de ubicaciones (GET) con feedback propio.
  Future<void> _onDownloadLocations(
    DownloadLocationsEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(const DownloadUserDataLoading('Descargando ubicaciones...'));
    try {
      final result = await getUserLocations(NoParams());
      String? error;
      result.fold(
        (failure) => error = failure.message,
        (data) => locations = data,
      );
      if (error != null) {
        emit(DownloadUserDataError(error!));
        return;
      }
      locationsCount = await DataBaseSqlite().getUbicacionesCount();
      emit(
        DownloadUserDataSuccess('Se descargaron $locationsCount ubicaciones'),
      );
    } catch (e) {
      debugPrint("❌ Error en _onDownloadLocations: $e");
      emit(DownloadUserDataError(e.toString()));
    }
  }

  /// Descarga bajo demanda de novedades (GET picking_novelties) con feedback.
  Future<void> _onDownloadNovelties(
    DownloadNoveltiesEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(const DownloadUserDataLoading('Descargando novedades...'));
    try {
      final result = await getUserNovelties(NoParams());
      String? error;
      result.fold(
        (failure) => error = failure.message,
        (data) => novelties = data,
      );
      if (error != null) {
        emit(DownloadUserDataError(error!));
        return;
      }
      noveltiesCount = await DataBaseSqlite().getNovedadesCount();
      emit(DownloadUserDataSuccess('Se descargaron $noveltiesCount novedades'));
    } catch (e) {
      debugPrint("❌ Error en _onDownloadNovelties: $e");
      emit(DownloadUserDataError(e.toString()));
    }
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
    String mac =
        (await getIt<IDeviceInfoService>().getMacAddress()) ??
        ''; // mac del dispositivo
    String imei =
        (await getIt<IDeviceInfoService>().getImei()) ??
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
    // getUserConfiguration ya cae a la config guardada en caché si no hay
    // conexión real (o si la petición remota falla); avisamos aquí para que
    // la UI muestre el aviso de "sin conexión" en vez de dejar que el usuario
    // piense que está viendo los datos más recientes del servidor.
    if (!await _networkInfo.isConnected) {
      emit(UserOfflineWarning());
    }

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
          await DataBaseSqlite().configurationsRepository.insertConfiguration(
            config!,
            userId,
          );
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
    // Ubicaciones y novedades ya NO se piden por red al entrar a la pantalla
    // (se evita el GET de ubicaciones y el GET picking_novelties automáticos).
    // Solo cargamos los conteos locales; la descarga se hace con el botón
    // "Descargar novedades y ubicaciones" (DownloadNoveltiesAndLocationsEvent).
    add(LoadUserLocationsCountEvent());
    add(LoadUserNoveltiesCountEvent());

    if (config != null && deviceInfo != null) {
      userConfiguration = config;
      this.deviceInfo = deviceInfo;

      emit(
        UserLoaded(
          configuration: userConfiguration!,
          deviceInfo: this.deviceInfo!,
          locations: locations,
          novelties: novelties,
        ),
      );
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
        deviceId = info.mac == "02:00:00:00:00:00" ? info.imei : info.mac;
        deviceModel = info.model;
        deviceName = '${info.model} ${info.manufacturer}';
        versionApp = info.appVersion;
      });
    }

    if (deviceId != null) {
      emit(DeviceRegistrationLoading());
      final result = await registerDevice(
        RegisterDeviceParams(
          deviceId: deviceId!,
          deviceName: deviceName!,
          deviceModel: deviceModel!,
          versionApp: versionApp!,
        ),
      );

      await result.fold(
        (failure) async => emit(DeviceRegistrationFailure(failure.message)),
        (registration) async {
          if (registration.isAuthorized == 'yes') {
            // Guardar sesión solo después de que el dispositivo esté autorizado
            if (event.user != null && event.password != null) {
              final saveResult = await saveUserSession(
                SaveSessionParams(user: event.user!, password: event.password!),
              );
              saveResult.fold(
                (_) => debugPrint(
                  '⚠️ Session save failed after device authorization',
                ),
                (_) =>
                    debugPrint('💾 Session saved after device authorization'),
              );
            }
            emit(DeviceRegistrationSuccess());
            add(LoadUserInfoEvent());
          } else {
            emit(
              const DeviceRegistrationFailure(
                'Su dispositivo no esta autorizado',
              ),
            );
          }
        },
      );
    } else {
      emit(
        const DeviceRegistrationFailure(
          "Could not get device info for registration",
        ),
      );
    }
  }

  Future<void> _onLoadUserLocations(
    LoadUserLocationsEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLocationsLoading());
    final result = await getUserLocations(NoParams());
    bool success = false;
    result.fold((failure) => emit(UserLocationsError(failure.message)), (
      locations,
    ) {
      this.locations = locations;
      debugPrint('Locations loaded from API: ${locations.length}');
      success = true;
      emit(UserLocationsLoaded(locations: locations));
    });
    if (success) {
      try {
        locationsCount = await DataBaseSqlite().getUbicacionesCount();
        debugPrint('Locations saved in DB: $locationsCount');
      } catch (e) {
        debugPrint("❌ Error getting locations count from DB: $e");
      }
    }
  }

  Future<void> _onLoadUserNovelties(
    LoadUserNoveltiesEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserNoveltiesLoading());
    final result = await getUserNovelties(NoParams());
    result.fold((failure) => emit(UserNoveltiesError(failure.message)), (
      novelties,
    ) {
      this.novelties = novelties;
      noveltiesCount = novelties.length;
    });
  }

  Future<void> _onLoadUserLocationsCount(
    LoadUserLocationsCountEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      locationsCount = await DataBaseSqlite().getUbicacionesCount();
      emit(LoadLocationsCountSuccess(locationsCount));
    } catch (e) {
      debugPrint("❌ Error en _onLoadUserLocationsCount: $e");
    }
  }

  Future<void> _onLoadUserNoveltiesCount(
    LoadUserNoveltiesCountEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      noveltiesCount = await DataBaseSqlite().getNovedadesCount();
      emit(LoadNoveltiesCountSuccess(noveltiesCount));
    } catch (e) {
      debugPrint("❌ Error en _onLoadUserNoveltiesCount: $e");
    }
  }

  Future<void> _onLoadWarehousesCount(
    LoadWarehousesCountEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      warehousesCount = await DataBaseSqlite().getWarehousesCount();
      emit(LoadWarehousesCountSuccess(warehousesCount));
    } catch (e) {
      debugPrint("❌ Error en _onLoadWarehousesCount: $e");
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

  // Bug: ni _onLoadUserNovelties ni _onDownloadNovelties emiten
  // UserNoveltiesLoaded (ese estado no se emite en ningún lado del bloc), y
  // UserLoaded.novelties queda siempre vacío porque _onLoadUserInfo ya no
  // pide novedades por red (ver comentario en _onLoadUserInfo). Los dos
  // handlers de novedades sí actualizan el campo `novelties` del bloc, así
  // que ese es el que hay que leer — no el state.
  List<Novedad> get novedades => novelties;

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
