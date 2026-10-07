import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';

class GetBarcodesProductoPackParams {
  final ProductoPacking producto;

  const GetBarcodesProductoPackParams({required this.producto});
}

/// Barcodes alternos (y de empaque) de la línea.
@lazySingleton
class GetBarcodesProductoPackUseCase
    implements
        UseCase<List<BarcodeProductoPacking>, GetBarcodesProductoPackParams> {
  final PackingPedidoRepository repository;

  GetBarcodesProductoPackUseCase(this.repository);

  @override
  Future<Either<Failure, List<BarcodeProductoPacking>>> call(
    GetBarcodesProductoPackParams params,
  ) {
    return repository.getBarcodesProducto(params.producto);
  }
}
