// lib/features/inventario/domain/repositories/inventario_repository.dart

import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/inventario/domain/entities/barcode_producto.dart';
import 'package:wms_app/features/inventario/domain/entities/lote_producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/entities/producto_inventario.dart';
import 'package:wms_app/features/inventario/domain/entities/resultado_crear_lote.dart';
import 'package:wms_app/features/inventario/domain/entities/resultado_envio_inventario.dart';
import 'package:wms_app/features/inventario/domain/entities/ubicacion_inventario.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';

abstract class InventarioRepository {
  Future<Either<Failure, void>> syncProductosInventario(bool isLoadingDialog);

  Future<Either<Failure, List<ProductoInventario>>> getProductosLocal();

  Future<Either<Failure, int>> getProductosCount();

  Future<Either<Failure, List<UbicacionInventario>>> getUbicacionesLocal();

  Future<Either<Failure, List<LoteProductoInventario>>> getLotesProducto(
      int productId);

  Future<Either<Failure, ResultadoEnvioInventario>> enviarProductoInventario({
    required dynamic locationId,
    required dynamic productId,
    required dynamic lotId,
    required dynamic quantity,
  });

  Future<Either<Failure, ResultadoCrearLote>> crearLoteInventario({
    required int productId,
    required String nameLote,
    required String fechaCaducidad,
    required bool priorityExpiration,
  });

  Future<Either<Failure, List<BarcodeProducto>>> getBarcodesProducto(
      int productId);

  Future<Either<Failure, List<BarcodeProducto>>> getAllBarcodesInventario();

  Future<Either<Failure, UserConfiguration>> getConfiguracionUsuarioInventario();

  /// URL de la imagen de un producto (usada también por otros módulos:
  /// picking, recepción, conteo, packing, transferencias e info rápida).
  Future<Either<Failure, String>> getUrlImagenProducto(int productId);
}
