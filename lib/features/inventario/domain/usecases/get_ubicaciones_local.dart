// lib/features/inventario/domain/usecases/get_ubicaciones_local.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/inventario/domain/entities/ubicacion_inventario.dart';
import 'package:wms_app/features/inventario/domain/repositories/inventario_repository.dart';

@lazySingleton
class GetUbicacionesLocal
    implements UseCase<List<UbicacionInventario>, NoParams> {
  final InventarioRepository repository;

  GetUbicacionesLocal(this.repository);

  @override
  Future<Either<Failure, List<UbicacionInventario>>> call(NoParams params) {
    return repository.getUbicacionesLocal();
  }
}
