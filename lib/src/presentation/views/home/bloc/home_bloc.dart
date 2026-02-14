// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/home/data/home_repository.dart';
import 'package:wms_app/src/presentation/views/home/data/models/app_version_model.dart';
import 'package:wms_app/src/presentation/views/user/models/configuration.dart';
import 'package:wms_app/src/services/webSocket_service.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  String userName = "";
  String userEmail = "";
  String userImage = "";
  String userRol = "";

  String versionApp = "";

  AppVersion appVersion = AppVersion();

  HomeRepository homeRepository = HomeRepository();

  //*configuracion del usuario //permisos
  Configurations configurations = Configurations();

  DataBaseSqlite db = DataBaseSqlite();

  final WebSocketService _webSocketService =
      WebSocketService(); // Instancia del servicio
  late StreamSubscription _webSocketSubscription; // Para gestionar el listener

  HomeBloc() : super(HomeInitial()) {
// ✅ 1. INICIAR LA SUSCRIPCIÓN EN EL CONSTRUCTOR DEL BLOQUE
    _webSocketSubscription =
        _webSocketService.messages.listen(_onWebSocketMessage);

    // ✅ 2. MAPEAR EL EVENTO DE RECEPCIÓN DE MENSAJES
    on<WebSocketMessageReceived>(_handleIncomingWebSocketData);

    on<HomeLoadData>((event, emit) async {
      emit(HomeLoadingState());
      try {
        userName = await PrefUtils.getUserName();
        userEmail = await PrefUtils.getUserEmail();
        userRol = await PrefUtils.getUserRol();
        emit(HomeLoadedState());
      } catch (e) {
        emit(HomeLoadErrorState());
      }
    });
    add(HomeLoadData());

    //*obtener las configuraciones y permisos del usuario desde la bd
    on<LoadConfigurationsUserHome>(_onLoadConfigurationsUserEvent);

    on<AppVersionEvent>((event, emit) async {
      emit(AppVersionLoadingState());
      try {
        final response = await homeRepository.getAppVersion();
        if (response.result == null) {
          emit(AppVersionLoadErrorState(response.message));
          return;
        }
        appVersion = response;
        // Obtenemos la versión de la app
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String version = packageInfo.version; // Versión de la app

        // Comparamos las versiones
        String currentVersion = appVersion.result?.result?.version ?? '';

        if (version == currentVersion) {
          // Si las versiones son iguales, la app está actualizada
          print('La app está actualizada: $version');
          emit(AppVersionLoadedState(appVersion));
        } else if (version.compareTo(currentVersion) > 0) {
          // Si la versión local es mayor (es decir, está más actualizada)
          print('La app está más actualizada: $version');
          emit(AppVersionLoadedState(appVersion)); // Ya está actualizada
        } else if (version.compareTo(currentVersion) < 0) {
          print('Hay una actualización disponible: $version');
          // Si la versión local es menor, hay una actualización disponible
          emit(AppVersionUpdateState(appVersion));
        }
      } catch (e) {
        emit(
            AppVersionLoadErrorState('Error al obtener la versión de la app '));
      }
    });
  }

  // ✅ 3. MANEJADOR QUE RECIBE EL MENSAJE Y LO CONVIERTE EN EVENTO
  void _onWebSocketMessage(dynamic data) {
    // Aquí puedes pre-procesar el mensaje (ej. decodificar JSON) antes de enviarlo como evento.
    // Por ahora, asumimos que 'data' es un JSON o String.
    add(WebSocketMessageReceived(data));
  }

  // ✅ 4. LÓGICA DE REACCIÓN A DATOS EN TIEMPO REAL
  void _handleIncomingWebSocketData(
      WebSocketMessageReceived event, Emitter<HomeState> emit) {
    print('HomeBloc: Mensaje WebSocket en tiempo real: ${event.payload}');

    // ⚠️ LÓGICA CLAVE: Aquí iría el código para actualizar el estado del BLoC
    // Por ejemplo, si el servidor envía {'type': 'NEW_ORDER'}:
    // if (event.payload is Map && event.payload['type'] == 'NEW_ORDER') {
    //   emit(HomeDataUpdatedState(newOrderAlert: true));
    // }
  }

  @override
  Future<void> close() {
    // 5. CANCELAR LA SUSCRIPCIÓN AL CERRAR EL BLOQUE (¡Crucial para evitar fugas!)
    _webSocketSubscription.cancel();
    return super.close();
  }

  void _onLoadConfigurationsUserEvent(
      LoadConfigurationsUserHome event, Emitter<HomeState> emit) async {
    emit(HomeLoadingState());
    try {
      int userId = await PrefUtils.getUserId();
      final response =
          await db.configurationsRepository.getConfiguration(userId);
      if (response != null) {
        configurations = response;
        emit(ConfigurationLoadedHomeState(response));
      } else {
        emit(ConfigurationErrorHomeState('Error al cargar configuraciones'));
      }
    } catch (e, s) {
      emit(ConfigurationErrorHomeState(e.toString()));
      print('Error en LoadConfigurationsUserPack.dart: $e =>$s');
    }
  }
}
