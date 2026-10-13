// lib/features/inventario/domain/usecases/get_ubicacion_por_barcode.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/ubicacion_inventario.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

/// Ubicación escaneada (barcode sin distinguir mayúsculas); `null` si no
/// existe en la tabla local.
@lazySingleton
class GetUbicacionPorBarcode
    implements UseCase<UbicacionInventario?, String> {
  final InventarioRepository repository;

  GetUbicacionPorBarcode(this.repository);

  @override
  Future<Either<Failure, UbicacionInventario?>> call(String barcode) {
    return repository.getUbicacionPorBarcode(barcode);
  }
}
