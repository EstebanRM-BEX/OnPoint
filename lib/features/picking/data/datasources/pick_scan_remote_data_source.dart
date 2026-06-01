import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/views/inventario/data/inventario_repository.dart';
import 'package:wms_app/src/presentation/views/transferencias/data/transferencias_repository.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/requets_transfer_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/data/wms_picking_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/submeuelle_model.dart';

abstract class PickScanRemoteDataSource {
  Future<List<Muelles>> getMuelles();
  Future<String> getProductImageUrl(int productId);
  Future<String> validateConfirmPick(int pickId, bool isBackOrder);
  Future<String> validateTransfer(int pickId, bool isBackOrder);
  Future<bool> sendTime(int pickId, String timeType, String time);
  Future<bool> ocuparMuelle(int idMuelle, bool isFull);
  Future<String> sendProductTransferPick(TransferRequest request);
}

@LazySingleton(as: PickScanRemoteDataSource)
class PickScanRemoteDataSourceImpl implements PickScanRemoteDataSource {
  @override
  Future<List<Muelles>> getMuelles() async {
    final response = await WmsPickingRepository().getmuelles(false);
    if (response == null) return [];
    return response;
  }

  @override
  Future<String> getProductImageUrl(int productId) async {
    final response =
        await InventarioRepository().viewUrlImageProduct(productId, true);
    if (response.result?.code == 200 &&
        response.result?.result?.url != null &&
        response.result!.result!.url!.isNotEmpty) {
      return response.result!.result!.url!;
    }
    throw Exception('Imagen no disponible');
  }

  @override
  Future<String> validateConfirmPick(int pickId, bool isBackOrder) async {
    final response = await TransferenciasRepository()
        .confirmationValidate(pickId, isBackOrder, false);
    if (response.result?.code == 200) {
      return response.result?.msg ?? '';
    }
    throw Exception(response.result?.msg ?? 'Error al validar confirmación');
  }

  @override
  Future<String> validateTransfer(int pickId, bool isBackOrder) async {
    final response = await TransferenciasRepository()
        .validateTransfer(pickId, isBackOrder, false);
    if (response.result?.code == 200) {
      return response.result?.msg ?? '';
    }
    throw Exception(response.result?.msg ?? 'Error al validar transferencia');
  }

  @override
  Future<bool> sendTime(int pickId, String timeType, String time) async {
    return await TransferenciasRepository()
        .sendTime(pickId, timeType, time, false);
  }

  @override
  Future<bool> ocuparMuelle(int idMuelle, bool isFull) async {
    final response = await WmsPickingRepository()
        .ocuparMuelle(idMuelle: idMuelle, isFull: isFull);
    return response.result?.code == 200;
  }

  @override
  Future<String> sendProductTransferPick(TransferRequest request) async {
    final response =
        await TransferenciasRepository().sendProductTransferPick(request, false);
    if (response.result?.code == 200) {
      return response.result?.msg ?? '';
    }
    throw Exception(
        response.result?.msg ?? 'Error al enviar producto a Odoo');
  }
}
