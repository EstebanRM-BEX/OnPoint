import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wms_app/features/home/domain/entities/app_version.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/features/inventario/presentation/bloc/inventario_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/bloc/wms_picking_bloc.dart';

/// Destino de navegación al terminar el arranque post-login.
enum PostLoginDestination { home, updateRequired }

/// Resultado del arranque post-login: a dónde navegar y, si aplica,
/// los datos de la versión para la pantalla de actualización obligatoria.
class PostLoginResult {
  final PostLoginDestination destination;
  final AppVersion? appVersion;

  const PostLoginResult({required this.destination, this.appVersion});
}

/// Orquesta la secuencia de arranque después de un login exitoso:
/// configuraciones → versión de la app → precargas en background.
///
/// Vive fuera del árbol de widgets: la UI solo espera el resultado y navega,
/// y la secuencia se puede testear con blocs mockeados sin montar pantallas.
class PostLoginCoordinator {
  final HomeBloc homeBloc;
  final DevolucionesBloc devolucionesBloc;
  final WMSPickingBloc pickingBloc;
  final InventarioBloc inventarioBloc;
  final UserBloc userBloc;

  PostLoginCoordinator({
    required this.homeBloc,
    required this.devolucionesBloc,
    required this.pickingBloc,
    required this.inventarioBloc,
    required this.userBloc,
  });

  Future<PostLoginResult> run() async {
    // ── PASO 1: Recargar datos del usuario y configuraciones ──
    homeBloc.add(HomeLoadData());
    homeBloc.add(LoadConfigurationsEvent());

    final configState = await _waitForHomeState(
      (s) => s is ConfigurationLoadedHomeState || s is ConfigurationErrorHomeState,
      const Duration(seconds: 15),
    );
    debugPrint('⚙️ [PostLogin] Configuraciones: ${configState?.runtimeType}');

    // ── PASO 2: Versión de la app ──
    homeBloc.add(AppVersionEvent());

    final versionState = await _waitForHomeState(
      (s) =>
          s is AppVersionUpdateState ||
          s is AppVersionLoadedState ||
          s is AppVersionLoadErrorState,
      const Duration(seconds: 10),
    );
    debugPrint('📱 [PostLogin] Versión: ${versionState?.runtimeType}');

    // ── PASO 3: Precargas en background (fire & forget) ──
    devolucionesBloc.add(DownloadAllTercerosEvent());
    pickingBloc.add(LoadAllNovedades());
    inventarioBloc.add(GetProductsEvent(isDialogLoading: false));
    // Descarga de red de ubicaciones y novedades (GET picking_novelties), igual
    // que productos y terceros. Antes solo estaban bajo demanda en el perfil.
    userBloc.add(DownloadLocationsEvent());
    userBloc.add(DownloadNoveltiesEvent());

    if (versionState is AppVersionUpdateState) {
      return PostLoginResult(
        destination: PostLoginDestination.updateRequired,
        appVersion: versionState.appVersion,
      );
    }
    return const PostLoginResult(destination: PostLoginDestination.home);
  }

  /// Espera el primer estado del HomeBloc que cumpla [test].
  /// Devuelve null si expira [timeout]; el flujo de arranque continúa igual.
  Future<HomeState?> _waitForHomeState(
    bool Function(HomeState) test,
    Duration timeout,
  ) async {
    try {
      return await homeBloc.stream.firstWhere(test).timeout(timeout);
    } catch (_) {
      return null;
    }
  }
}
