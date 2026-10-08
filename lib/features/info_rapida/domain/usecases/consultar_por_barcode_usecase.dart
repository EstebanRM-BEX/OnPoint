import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

class ConsultarPorBarcodeParams extends Equatable {
  final String barcode;

  const ConsultarPorBarcodeParams({required this.barcode});

  @override
  List<Object?> get props => [barcode];
}

@lazySingleton
class ConsultarPorBarcodeUseCase
    implements UseCase<InfoRapida, ConsultarPorBarcodeParams> {
  final InfoRapidaRepository repository;

  ConsultarPorBarcodeUseCase(this.repository);

  @override
  Future<Either<Failure, InfoRapida>> call(
    ConsultarPorBarcodeParams params,
  ) async {
    return await repository.consultarPorBarcode(params.barcode);
  }
}
