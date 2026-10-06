import 'package:flutter/foundation.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/services/productos_cache_service.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_productos_count.dart';
import 'package:wms_app/features/inventario/domain/usecases/sync_productos_inventario.dart';
import 'package:wms_app/injection_container.dart';

/// Avance de la descarga de productos (fase actual y filas procesadas).
class ProductosSyncProgress {
  const ProductosSyncProgress({
    required this.phase,
    this.processed = 0,
    this.total = 0,
  });

  final String phase;
  final int processed;
  final int total;

  /// Texto listo para un diálogo de carga.
  String get label =>
      total > 0 ? '$phase\n$processed / $total productos' : phase;
}

/// Resultado de [ProductosSyncService.download]. Nunca se lanza una
/// excepción: cada pantalla decide qué mostrar según el caso.
sealed class ProductosSyncOutcome {
  const ProductosSyncOutcome();
}

class ProductosSyncSuccess extends ProductosSyncOutcome {
  const ProductosSyncSuccess(this.count);
  final int count;
}

class ProductosSyncFailure extends ProductosSyncOutcome {
  const ProductosSyncFailure(this.message);
  final String message;
}

/// La sesión caducó durante la descarga (quien llama muestra el aviso).
class ProductosSyncSessionExpired extends ProductosSyncOutcome {
  const ProductosSyncSessionExpired(this.message);
  final String message;
}

/// Ya hay una descarga en curso: no se lanzó otra.
class ProductosSyncAlreadyRunning extends ProductosSyncOutcome {
  const ProductosSyncAlreadyRunning();
}

/// Descarga del catálogo de productos (Odoo → SQLite) y su estado observable.
///
/// Antes vivía en `InventarioBloc` (global), que el login, el Home y el perfil
/// usaban solo para esto. Como servicio, quien lo necesita hace
/// `await download()` y quien solo muestra el estado escucha con un
/// `ListenableBuilder` (mismo patrón que `PreloadStatus`), sin mantener un bloc
/// vivo con listas y controllers.
class ProductosSyncService extends ChangeNotifier {
  ProductosSyncService({
    required SyncProductosInventario syncProductos,
    required GetProductosCount getProductosCount,
    required ProductosCacheService cache,
  }) : _syncProductos = syncProductos,
       _getProductosCount = getProductosCount,
       _cache = cache;

  final SyncProductosInventario _syncProductos;
  final GetProductosCount _getProductosCount;
  final ProductosCacheService _cache;

  static ProductosSyncService? _instance;

  /// Instancia compartida. Se arma al primer uso (el DI ya está inicializado),
  /// sin pasar por `build_runner`.
  static ProductosSyncService get instance =>
      _instance ??= ProductosSyncService(
        syncProductos: getIt<SyncProductosInventario>(),
        getProductosCount: getIt<GetProductosCount>(),
        cache: getIt<ProductosCacheService>(),
      );

  @visibleForTesting
  static set instance(ProductosSyncService? value) => _instance = value;

  bool _isLoading = false;
  int _count = 0;
  String? _error;
  ProductosSyncProgress? _progress;

  /// Hay una descarga en curso.
  bool get isLoading => _isLoading;

  /// Productos en SQLite (0 hasta la primera descarga o lectura).
  int get count => _count;

  /// Último error de la descarga o la lectura; null si fue bien.
  String? get error => _error;

  /// Avance de la descarga en curso; null si no hay ninguna.
  ProductosSyncProgress? get progress => _progress;

  /// Descarga todos los productos, reemplaza los de SQLite e invalida el caché
  /// compartido para que Conteo, Devoluciones, Info Rápida, etc. lean lo nuevo.
  Future<ProductosSyncOutcome> download({bool isLoadingDialog = false}) async {
    if (_isLoading) return const ProductosSyncAlreadyRunning();
    _isLoading = true;
    _error = null;
    _progress = null;
    notifyListeners();

    try {
      final syncResult = await _syncProductos(
        SyncProductosParams(
          isLoadingDialog: isLoadingDialog,
          onProgress: (phase, processed, total) {
            _progress = ProductosSyncProgress(
              phase: phase,
              processed: processed,
              total: total,
            );
            notifyListeners();
          },
        ),
      );

      final failure = syncResult.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) {
        _error = failure.message;
        return failure is SessionExpiredFailure
            ? ProductosSyncSessionExpired(failure.message)
            : ProductosSyncFailure(failure.message);
      }

      // El sync acaba de escribir productos frescos: el caché en memoria quedó
      // viejo.
      _cache.invalidate();

      final countResult = await _getProductosCount(NoParams());
      return countResult.fold<ProductosSyncOutcome>(
        (f) {
          _error = f.message;
          return ProductosSyncFailure(f.message);
        },
        (count) {
          _count = count;
          if (count == 0) {
            _error = 'No se encontraron productos';
            return ProductosSyncFailure(_error!);
          }
          return ProductosSyncSuccess(count);
        },
      );
    } catch (e, s) {
      // Sin esto, una excepción dejaba el estado en "cargando" para siempre y
      // el Home mostraba el spinner de Productos sin fin.
      debugPrint('❌ ProductosSyncService.download: $e -> $s');
      _error = 'No se pudieron descargar los productos';
      return ProductosSyncFailure(_error!);
    } finally {
      _isLoading = false;
      _progress = null;
      notifyListeners();
    }
  }

  /// Relee el conteo de productos de SQLite (sin descargar nada).
  Future<void> refreshCount() async {
    final result = await _getProductosCount(NoParams());
    result.fold(
      (f) => debugPrint('Error al obtener conteo de productos: ${f.message}'),
      (count) {
        if (count == _count) return;
        _count = count;
        notifyListeners();
      },
    );
  }
}
