import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/expedition/data/models/expedicion_response_model.dart';
import 'package:wms_app/src/api/api_request_service.dart';

abstract class ExpeditionRemoteDataSource {
  Future<ExpedicionResponseModel> fetchExpediciones({
    required bool isLoadinDialog,
  });
}

@LazySingleton(as: ExpeditionRemoteDataSource)
class ExpeditionRemoteDataSourceImpl implements ExpeditionRemoteDataSource {
  @override
  Future<ExpedicionResponseModel> fetchExpediciones({
    required bool isLoadinDialog,
  }) async {
    final response = await ApiRequestService().getValidation(
      endpoint: 'transferencias/out',
      isunecodePath: true,
      isLoadinDialog: isLoadinDialog,
    );

    if (response.statusCode >= 400) {
      throw ServerException('Error de conexión (${response.statusCode})');
    }

    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    final parsed = ExpedicionResponseModel.fromJson(jsonResponse);

    if (parsed.code != 200) {
      throw ServerException(parsed.msg ?? 'Error desconocido al obtener expediciones');
    }

    return parsed;
  }
}
