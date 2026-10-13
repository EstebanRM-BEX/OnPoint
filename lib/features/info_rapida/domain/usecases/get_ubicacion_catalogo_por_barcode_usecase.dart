import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

/// Ubicación escaneada (barcode sin distinguir mayúsculas); `null` si no
/// existe en el catálogo local.
@lazySingleton
class GetUbicacionCatalogoPorBarcodeUseCase
    implements UseCase<UbicacionCatalogo?, String> {
  final InfoRapidaRepository repository;

  GetUbicacionCatalogoPorBarcodeUseCase(this.repository);

  @override
  Future<Either<Failure, UbicacionCatalogo?>> call(String barcode) async {
    return await repository.getUbicacionCatalogoPorBarcode(barcode);
  }
}
