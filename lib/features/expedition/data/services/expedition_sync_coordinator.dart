import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/expedition/data/datasources/expedition_local_data_source.dart';
import 'package:wms_app/features/expedition/data/datasources/expedition_remote_data_source.dart';

/// Envía al backend, en segundo plano, las validaciones de expedición hechas
/// sin conexión (paquetes y productos sueltos con sync_pending = 1) apenas
/// vuelve la red, y las reintenta hasta que queden OK.
///
/// Diseñado para NO afectar el rendimiento de la app:
/// - Todo es I/O async (sqflite + http): nada corre en el hilo de UI ni en
///   `build`.
/// - Single-flight: nunca corre dos ciclos a la vez ([_syncing] + [_rerun]).
/// - Se dispara por eventos, no por polling: al volver la conexión
///   (onStatusChanged), al iniciar la app y tras validar. Solo cuando un envío
///   falla estando online programa UN reintento con backoff creciente
///   (cancelable), sin loops ajustados.
@lazySingleton
class ExpeditionSyncCoordinator {
  final NetworkInfo networkInfo;
  final ExpeditionRemoteDataSource remoteDataSource;
  final ExpeditionLocalDataSource localDataSource;

  StreamSubscription<ConnectionStatus>? _statusSub;

  bool _syncing = false;
  bool _rerun = false;

  Timer? _retryTimer;
  int _retryIndex = 0;
  static const List<Duration> _backoff = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(seconds: 120),
  ];

  // La UI (lista/detalle) se suscribe para refrescar cuando algo se sincroniza.
  final StreamController<void> _syncedController =
      StreamController<void>.broadcast();
  Stream<void> get onSynced => _syncedController.stream;

  ExpeditionSyncCoordinator({
    required this.networkInfo,
    required this.remoteDataSource,
    required this.localDataSource,
  }) {
    _statusSub = networkInfo.onStatusChanged.listen((status) {
      if (status == ConnectionStatus.online) requestSync();
    });
  }

  /// Pide un ciclo de sincronización. Idempotente y no bloqueante: si ya hay
  /// uno en curso, marca que debe repetirse al terminar. Se puede llamar al
  /// iniciar la app, al volver la conexión y después de validar.
  void requestSync() {
    _retryTimer?.cancel();
    unawaited(_run());
  }

  Future<void> _run() async {
    if (_syncing) {
      _rerun = true;
      return;
    }
    _syncing = true;

    bool huboCambios = false;
    bool quedanPendientes = false;
    try {
      final result = await _syncPendientes();
      huboCambios = result.$1;
      quedanPendientes = result.$2;
    } catch (e) {
      debugPrint('ExpeditionSyncCoordinator error: $e');
      quedanPendientes = true;
    } finally {
      _syncing = false;
    }

    if (huboCambios && !_syncedController.isClosed) {
      _syncedController.add(null);
    }

    if (_rerun) {
      _rerun = false;
      unawaited(_run());
      return;
    }

    if (quedanPendientes) {
      _scheduleRetry();
    } else {
      _retryIndex = 0;
      _retryTimer?.cancel();
    }
  }

  /// Devuelve (huboCambios, quedanPendientes).
  Future<(bool, bool)> _syncPendientes() async {
    if (!await networkInfo.isConnected) return (false, true);

    final paquetes = await localDataSource.getPaquetesPendientesSync();
    final items = await localDataSource.getItemsSueltosPendientesSync();
    if (paquetes.isEmpty && items.isEmpty) return (false, false);

    // Un solo send_out por expedición con todos sus packing_id pendientes.
    final Map<int, List<int>> porExpedicion = {};
    for (final p in paquetes) {
      if (p.expeditionId == null || p.packingId == null) continue;
      porExpedicion.putIfAbsent(p.expeditionId!, () => []).add(p.packingId!);
    }
    for (final i in items) {
      if (i.expeditionId == null || i.packingId == null) continue;
      porExpedicion.putIfAbsent(i.expeditionId!, () => []).add(i.packingId!);
    }

    bool huboCambios = false;
    bool quedanPendientes = false;

    for (final entry in porExpedicion.entries) {
      final expeditionId = entry.key;
      try {
        final ok = await remoteDataSource.validarMultiple(
          expeditionId: expeditionId,
          packingIds: entry.value,
        );
        if (!ok) {
          quedanPendientes = true;
          continue;
        }
        for (final p in paquetes) {
          if (p.expeditionId == expeditionId && p.packingId != null) {
            await localDataSource.marcarPaqueteSincronizado(p.packingId!);
          }
        }
        for (final i in items) {
          if (i.expeditionId == expeditionId && i.packingId != null) {
            await localDataSource.marcarItemSueltoSincronizado(
                expeditionId, i.packingId!);
          }
        }
        huboCambios = true;
      } catch (e) {
        // Deja esta expedición pendiente; se reintenta en el próximo ciclo.
        debugPrint('Sync expedición $expeditionId falló: $e');
        quedanPendientes = true;
      }
    }

    return (huboCambios, quedanPendientes);
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final delay = _backoff[_retryIndex.clamp(0, _backoff.length - 1)];
    if (_retryIndex < _backoff.length - 1) _retryIndex++;
    _retryTimer = Timer(delay, () => unawaited(_run()));
  }

  @disposeMethod
  void dispose() {
    _statusSub?.cancel();
    _retryTimer?.cancel();
    _syncedController.close();
  }
}
