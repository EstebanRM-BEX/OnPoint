import 'dart:collection';

import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart';

/// Cache en memoria del catálogo completo de barcodes de inventario
/// (tblbarcodes_inventario: barcode -> producto), compartido por toda la app.
///
/// A diferencia de tblbarcodes_packages (picking/packing/recepción), esta
/// tabla SÍ es un catálogo estático descargado una vez por sync y leído sin
/// cambios por varios blocs (CreateTransferBloc, DevolucionesBloc,
/// InventarioLocalDataSource) — mismo patrón que
/// [UbicacionesCacheService]/[ProductosCacheService]/[NovedadesCacheService].
/// tblbarcodes_packages en cambio se consulta por (batchId, idMove,
/// idProduct, barcodeType) — una key específica del batch/pedido en curso
/// de cada bloc, no una lista global compartida — por eso queda fuera de
/// este cache.
///
/// Una sola lista para toda la app: los consumidores reasignan directo
/// (`allBarcodeInventario = response;`), nunca mutan la lista in-place.
/// [getAll] devuelve un [UnmodifiableListView] — una vista (no copia el
/// arreglo interno: sigue siendo LA MISMA lista para todos) que convierte
/// cualquier intento futuro de `.clear()/.sort()/.add()` en un
/// UnsupportedError inmediato en vez de corromper el cache en silencio.
@lazySingleton
class BarcodesInventarioCacheService {
  List<BarcodeInventario>? _cache;

  Future<List<BarcodeInventario>> getAll({bool forceRefresh = false}) async {
    if (_cache == null || _cache!.isEmpty || forceRefresh) {
      _cache =
          await DataBaseSqlite().barcodesInventarioRepository.getAllBarcodes();
    }
    return UnmodifiableListView(_cache!);
  }

  Future<List<BarcodeInventario>> refresh() => getAll(forceRefresh: true);

  void invalidate() => _cache = null;
}
