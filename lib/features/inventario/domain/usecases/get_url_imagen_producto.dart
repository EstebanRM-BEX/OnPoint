// lib/features/inventario/domain/usecases/get_url_imagen_producto.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

@lazySingleton
class GetUrlImagenProducto
    implements UseCase<String, GetUrlImagenProductoParams> {
  final InventarioRepository repository;

  GetUrlImagenProducto(this.repository);

  @override
  Future<Either<Failure, String>> call(GetUrlImagenProductoParams params) {
    return repository.getUrlImagenProducto(params.productId);
  }
}

class GetUrlImagenProductoParams {
  final int productId;

  const GetUrlImagenProductoParams({required this.productId});
}
