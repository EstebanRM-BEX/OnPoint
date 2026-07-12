import 'package:wms_app/features/expedition/data/models/expedicion_pedido_model.dart';

/// Envuelve la respuesta cruda de `/api/transferencias/out`:
/// `{jsonrpc, id, result: {code, update_version, result: [...]}}`.
class ExpedicionResponseModel {
  final int? code;
  final bool? updateVersion;
  final String? msg;
  final List<ExpedicionPedidoModel> result;

  const ExpedicionResponseModel({
    this.code,
    this.updateVersion,
    this.msg,
    this.result = const [],
  });

  factory ExpedicionResponseModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? result =
        json['result'] as Map<String, dynamic>?;

    if (result == null) {
      return const ExpedicionResponseModel();
    }

    final List<dynamic> rawList = result['result'] as List<dynamic>? ?? [];

    return ExpedicionResponseModel(
      code: result['code'] as int?,
      updateVersion: result['update_version'] as bool?,
      msg: result['msg']?.toString(),
      result: rawList
          .map((x) => ExpedicionPedidoModel.fromJson(x as Map<String, dynamic>))
          .toList(),
    );
  }
}
