import 'dart:convert';
import 'dart:developer';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import '../entities/batch_product.dart';
import '../repositories/picking_cluster_repository.dart';

@lazySingleton
class SendProductOdooUseCase implements UseCase<String, SendProductOdooParams> {
  final IPickingClusterRepository repository;

  SendProductOdooUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(SendProductOdooParams params) async {
    try {
      // 1. Obtener UserID directamente de Utils
      final userid = await PrefUtils.getUserId();

      // 2. Cálculo lógico de tiempos
      double secondsDifference = 0.0;
      try {
        final DateTime dateTimeActuality = DateTime.now();
        final Duration difference =
            dateTimeActuality.difference(DateTime.now());
        secondsDifference = difference.inMilliseconds / 1000.0;
      } catch (e) {
        log('❌ Error al calcular tiempo: $e', name: 'SendProductOdooUseCase');
      }

      // 3. Lógica para cálculo de cantidades finales
      final double cantidadSeparada =
          (params.product.quantitySeparate ?? 0).toDouble();
      final double cantidadSolicitada =
          (params.product.quantity ?? 0).toDouble();

      final bool esExceso = cantidadSeparada > cantidadSolicitada;
      double cantidadFinal = esExceso ? cantidadSolicitada : cantidadSeparada;

      // 4. Construcción del payload según el nuevo requerimiento
      final Map<String, dynamic> itemMap = {
        "id_move": params.product.idMove ?? 0,
        "product_id": params.product.idProduct ?? 0,
        "id_lote": params.product.loteId ?? 0,
        "cantidad_separada": cantidadFinal,
        "observacion": (params.product.observation == null ||
                params.product.observation!.isEmpty)
            ? 'Sin novedad'
            : params.product.observation,
        "time_line": params.product.timeSeparate == null
            ? 10.0
            : (params.product.timeSeparate is String)
                ? double.tryParse(params.product.timeSeparate) ?? 10.0
                : (params.product.timeSeparate as num).toDouble(),
        "id_operario": userid,
        "fecha_transaccion":
            params.product.fechaTransaccion ?? DateTime.now().toString(),
      };

      // 5. Envío
      final response = await repository.sendPickingProduct(
        idBatch: params.product.batchId ?? 0,
        timeTotal: secondsDifference,
        cantItemsSeparados: 0,
        listItem: [itemMap],
        tipoPicking: params.type,
      );

      // 6. Interpretar respuesta
      return response.fold(
        (failure) => Left(failure),
        (jsonString) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(jsonString);
            if (decoded['result']?['code'] == 200) {
              return const Right('Ok');
            } else {
              return Left(ServerFailure(
                  decoded['result']?['msg'] ?? 'Error desconocido'));
            }
          } catch (e) {
            return Left(
                ServerFailure('Error al interpretar respuesta de Odoo'));
          }
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class SendProductOdooParams {
  final BatchProduct product;
  final String type;
  final UserConfigurationModel? configurations;

  SendProductOdooParams({
    required this.product,
    required this.type,
    this.configurations,
  });
}
