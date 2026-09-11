import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_session_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

abstract class TransferenciaMultiusuarioLocalDataSource {
  /// Borra todas las sesiones guardadas. Se llama antes de persistir un
  /// fetch nuevo: el guardado es un upsert por id, así que sin este barrido
  /// las sesiones que el backend ya no devuelve (finalizadas) se quedarían
  /// para siempre en la lista.
  Future<Unit> limpiarSessions();

  Future<Unit> saveSessions(List<TransferenciaSessionModel> sessions);

  Future<List<TransferenciaSessionModel>> getSessionsFromDb();
}

@LazySingleton(as: TransferenciaMultiusuarioLocalDataSource)
class TransferenciaMultiusuarioLocalDataSourceImpl
    implements TransferenciaMultiusuarioLocalDataSource {
  final DataBaseSqlite db = DataBaseSqlite();

  @override
  Future<Unit> limpiarSessions() async {
    await db.deleTransferenciaSessions();
    return unit;
  }

  @override
  Future<Unit> saveSessions(List<TransferenciaSessionModel> sessions) async {
    await db.transferenciaSessionsRepository.insertOrUpdateSessions(sessions);
    return unit;
  }

  @override
  Future<List<TransferenciaSessionModel>> getSessionsFromDb() async {
    return await db.transferenciaSessionsRepository.getAllSessions();
  }
}
