import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_pool_item_model.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_session_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

abstract class RecepcionMultiusuarioLocalDataSource {
  /// Borra todas las sesiones guardadas. Se llama antes de persistir un
  /// fetch nuevo: el guardado es un upsert por id, así que sin este barrido
  /// las sesiones que el backend ya no devuelve (finalizadas) se quedarían
  /// para siempre en la lista.
  Future<Unit> limpiarSessions();

  Future<Unit> saveSessions(List<RecepcionSessionModel> sessions);

  Future<List<RecepcionSessionModel>> getSessionsFromDb();

  /// Reemplaza por completo el pool local de [sessionId] por [items]: lo que
  /// no venga ya no está libre (otro operario lo tomó) y debe desaparecer.
  Future<Unit> savePool(int sessionId, List<RecepcionPoolItemModel> items);

  Future<List<RecepcionPoolItemModel>> getPoolFromDb(int sessionId);
}

@LazySingleton(as: RecepcionMultiusuarioLocalDataSource)
class RecepcionMultiusuarioLocalDataSourceImpl
    implements RecepcionMultiusuarioLocalDataSource {
  final DataBaseSqlite db = DataBaseSqlite();

  @override
  Future<Unit> limpiarSessions() async {
    await db.deleRecepcionSessions();
    return unit;
  }

  @override
  Future<Unit> saveSessions(List<RecepcionSessionModel> sessions) async {
    await db.recepcionSessionsRepository.insertOrUpdateSessions(sessions);
    return unit;
  }

  @override
  Future<List<RecepcionSessionModel>> getSessionsFromDb() async {
    return await db.recepcionSessionsRepository.getAllSessions();
  }

  @override
  Future<Unit> savePool(
    int sessionId,
    List<RecepcionPoolItemModel> items,
  ) async {
    await db.recepcionSessionPoolRepository.insertPool(sessionId, items);
    return unit;
  }

  @override
  Future<List<RecepcionPoolItemModel>> getPoolFromDb(int sessionId) async {
    return await db.recepcionSessionPoolRepository.getPoolBySession(sessionId);
  }
}
