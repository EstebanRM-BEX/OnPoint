// lib/features/inventario/domain/usecases/get_all_barcodes_inventario.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/barcode_producto.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

@lazySingleton
class GetAllBarcodesInventario
    implements UseCase<List<BarcodeProducto>, NoParams> {
  final InventarioRepository repository;

  GetAllBarcodesInventario(this.repository);

  @override
  Future<Either<Failure, List<BarcodeProducto>>> call(NoParams params) {
    return repository.getAllBarcodesInventario();
  }
}
