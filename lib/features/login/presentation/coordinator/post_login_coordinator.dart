import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wms_app/core/services/preload_status.dart';
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

    // ── PASO 3: Precargas en background (fire & forget, EN SERIE) ──
    unawaited(_runPreloads());

    if (versionState is AppVersionUpdateState) {
      return PostLoginResult(
        destination: PostLoginDestination.updateRequired,
        appVersion: versionState.appVersion,
      );
    }
    return const PostLoginResult(destination: PostLoginDestination.home);
  }

  /// Precargas pesadas una detrás de otra, no a la vez.
  ///
  /// Terceros (~45 MB, 322 mil filas) YA NO se precargan aquí: solo los usa
  /// Devoluciones, que los carga de SQLite al entrar y los descarga si la BD
  /// está vacía (ver `DevolucionesBloc._onLoadTercerosFromDBEvent`).
  ///
  /// Lanzadas en paralelo, `terceros` (~45 MB, 322 mil filas) y `product_quants`
  /// (~43 MB) se decodifican y se insertan en SQLite al mismo tiempo: la
  /// memoria de la app pasaba de ~420 MB a más de 800 MB en un minuto y
  /// Android la mataba con SIGKILL (low memory) estando en el home, sin que el
  /// operario hiciera nada. En serie el pico es el de UNA descarga.
  Future<void> _runPreloads() async {
    const heavyTimeout = Duration(minutes: 3);

    PreloadStatus.instance.start(const [
      PreloadStatus.productos,
      PreloadStatus.ubicaciones,
      PreloadStatus.novedades,
    ]);

    await _runAndWait<InventarioState>(
      stream: inventarioBloc.stream,
      start: () => inventarioBloc.add(GetProductsEvent(isDialogLoading: false)),
      isDone: (s) =>
          s is GetProductsSuccess ||
          s is GetProductsFailureInventory ||
          s is InventarioSessionExpiredState,
      timeout: heavyTimeout,
      label: 'productos',
      statusKey: PreloadStatus.productos,
    );

    await _runAndWait<UserState>(
      stream: userBloc.stream,
      start: () => userBloc.add(DownloadLocationsEvent()),
      isDone: (s) => s is DownloadUserDataSuccess || s is DownloadUserDataError,
      timeout: heavyTimeout,
      label: 'ubicaciones',
      statusKey: PreloadStatus.ubicaciones,
    );

    // Descarga de red de novedades (GET picking_novelties). Antes solo estaban
    // bajo demanda en el perfil.
    await _runAndWait<UserState>(
      stream: userBloc.stream,
      start: () => userBloc.add(DownloadNoveltiesEvent()),
      isDone: (s) => s is DownloadUserDataSuccess || s is DownloadUserDataError,
      timeout: const Duration(minutes: 1),
      label: 'novedades',
      statusKey: PreloadStatus.novedades,
    );

    pickingBloc.add(LoadAllNovedades());
  }

  /// Lanza [start] y espera el primer estado que cumpla [isDone] (o el
  /// timeout). Se suscribe ANTES de lanzar el evento para no perder un estado
  /// emitido de inmediato. Nunca lanza: si falla, la siguiente precarga sigue.
  Future<void> _runAndWait<S>({
    required Stream<S> stream,
    required void Function() start,
    required bool Function(S) isDone,
    required Duration timeout,
    required String label,
    required String statusKey,
  }) async {
    try {
      final done = stream.firstWhere(isDone).timeout(timeout);
      start();
      await done;
      debugPrint('📥 [PostLogin] Precarga $label terminada');
    } catch (e) {
      debugPrint('⚠️ [PostLogin] Precarga $label sin confirmar: $e');
    } finally {
      PreloadStatus.instance.done(statusKey);
    }
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
