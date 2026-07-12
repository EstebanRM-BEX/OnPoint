import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/features/expedition/data/models/expedicion_pedido_model.dart';
import 'package:wms_app/features/expedition/data/models/item_expedicion_model.dart';
import 'package:wms_app/features/expedition/data/models/item_suelto_expedicion_model.dart';
import 'package:wms_app/features/expedition/data/models/paquete_expedicion_model.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

abstract class ExpeditionLocalDataSource {
  /// Borra las 4 tablas de expedición. Se llama antes de persistir un fetch
  /// nuevo: el guardado es un upsert por id, así que sin este barrido las
  /// expediciones que el backend ya no devuelve (por ejemplo, las que se
  /// confirmaron) se quedarían para siempre en la lista.
  Future<Unit> limpiarExpediciones();

  Future<Unit> saveExpediciones(List<ExpedicionPedidoModel> pedidos);
  Future<Unit> savePaquetesForExpedicion(
      int expeditionId, List<PaqueteExpedicionModel> paquetes);
  Future<Unit> saveItemsForPaquete(
      int packingId, List<ItemExpedicionModel> items);
  Future<Unit> saveItemsSueltosForExpedicion(
      int expeditionId, List<ItemSueltoExpedicionModel> items);
  Future<List<ExpedicionPedidoModel>> getExpedicionesFromDb();
  Future<ExpedicionPedidoModel?> getExpedicionById(int expeditionId);
  Future<Unit> updateResponsable(
      int expeditionId, int userId, String userName);
  Future<Unit> updateStartTime(int expeditionId, String time);
  Future<ExpedicionDetail?> getExpedicionDetail(int expeditionId);
  Future<Unit> actualizarValidacionPaquete(int packingId, bool value);
  Future<Unit> actualizarValidacionItemSuelto(
      int expeditionId, int packingId, bool value);
  Future<Unit> marcarPedidoTerminado(int expeditionId, String endTime);
}

@LazySingleton(as: ExpeditionLocalDataSource)
class ExpeditionLocalDataSourceImpl implements ExpeditionLocalDataSource {
  final DataBaseSqlite db = DataBaseSqlite();

  @override
  Future<Unit> limpiarExpediciones() async {
    await db.deleExpedicion();
    return unit;
  }

  @override
  Future<Unit> saveExpediciones(List<ExpedicionPedidoModel> pedidos) async {
    await db.expedicionPedidosRepository.insertOrUpdateExpediciones(pedidos);
    return unit;
  }

  @override
  Future<Unit> savePaquetesForExpedicion(
      int expeditionId, List<PaqueteExpedicionModel> paquetes) async {
    await db.expedicionPaquetesRepository
        .insertPaquetesForExpedicion(expeditionId, paquetes);
    return unit;
  }

  @override
  Future<Unit> saveItemsForPaquete(
      int packingId, List<ItemExpedicionModel> items) async {
    await db.expedicionItemsRepository
        .insertItemsForPaquete(packingId, items);
    return unit;
  }

  @override
  Future<Unit> saveItemsSueltosForExpedicion(
      int expeditionId, List<ItemSueltoExpedicionModel> items) async {
    await db.expedicionItemsSueltosRepository
        .insertItemsSueltosForExpedicion(expeditionId, items);
    return unit;
  }

  @override
  Future<List<ExpedicionPedidoModel>> getExpedicionesFromDb() async {
    return await db.expedicionPedidosRepository.getAllExpediciones();
  }

  @override
  Future<ExpedicionPedidoModel?> getExpedicionById(int expeditionId) async {
    return await db.expedicionPedidosRepository.getExpedicionById(expeditionId);
  }

  @override
  Future<Unit> updateResponsable(
      int expeditionId, int userId, String userName) async {
    await db.expedicionPedidosRepository
        .updateField(expeditionId, 'responsable_id', userId);
    await db.expedicionPedidosRepository
        .updateField(expeditionId, 'responsable', userName);
    return unit;
  }

  @override
  Future<Unit> updateStartTime(int expeditionId, String time) async {
    await db.expedicionPedidosRepository
        .updateField(expeditionId, 'start_time_transfer', time);
    return unit;
  }

  @override
  Future<ExpedicionDetail?> getExpedicionDetail(int expeditionId) async {
    final pedido =
        await db.expedicionPedidosRepository.getExpedicionById(expeditionId);
    if (pedido == null) return null;

    final paquetes = await db.expedicionPaquetesRepository
        .getPaquetesByExpedicion(expeditionId);

    final paquetesConItems = <PaqueteExpedicionModel>[];
    for (final paquete in paquetes) {
      if (paquete.packingId == null) {
        paquetesConItems.add(paquete);
        continue;
      }
      final items = await db.expedicionItemsRepository
          .getItemsByPaquete(paquete.packingId!);
      paquetesConItems.add(paquete.copyWithItems(items));
    }

    final itemsSueltos = await db.expedicionItemsSueltosRepository
        .getItemsSueltosByExpedicion(expeditionId);

    return ExpedicionDetail(
      pedido: pedido,
      paquetes: paquetesConItems,
      itemsSueltos: itemsSueltos,
    );
  }

  @override
  Future<Unit> actualizarValidacionPaquete(int packingId, bool value) async {
    await db.expedicionPaquetesRepository.updateIsValidate(packingId, value);
    await db.expedicionItemsRepository
        .updateIsValidateForPaquete(packingId, value);
    return unit;
  }

  @override
  Future<Unit> actualizarValidacionItemSuelto(
      int expeditionId, int packingId, bool value) async {
    await db.expedicionItemsSueltosRepository.updateIsValidate(
      expeditionId: expeditionId,
      packingId: packingId,
      value: value,
    );
    return unit;
  }

  @override
  Future<Unit> marcarPedidoTerminado(int expeditionId, String endTime) async {
    await db.expedicionPedidosRepository
        .updateField(expeditionId, 'is_terminated', 1);
    await db.expedicionPedidosRepository
        .updateField(expeditionId, 'end_time_transfer', endTime);
    return unit;
  }
}
