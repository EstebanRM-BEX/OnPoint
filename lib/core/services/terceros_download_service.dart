import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/devoluciones/data/devoluciones_repository.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/response_terceros_model.dart';

/// Descarga de terceros (~45 MB, 322 mil filas) desde Odoo a SQLite.
///
/// Vive fuera de `DevolucionesBloc` para que el perfil pueda sincronizar
/// terceros sin que el bloc de devoluciones exista (solo se crea al entrar
/// a una devolución).
class TercerosDownloadService {
  TercerosDownloadService({
    DevolucionesRepository? repository,
    DataBaseSqlite? db,
  }) : _repository = repository ?? DevolucionesRepository(),
       _db = db ?? DataBaseSqlite();

  final DevolucionesRepository _repository;
  final DataBaseSqlite _db;

  /// Evita dos descargas simultáneas (cada una duplica el pico de memoria).
  static bool _running = false;

  static bool get isRunning => _running;

  /// Descarga todos los terceros y reemplaza la tabla local.
  ///
  /// Devuelve la lista descargada. Lanza [TercerosDownloadException] si la
  /// nube no devuelve terceros, o si ya hay una descarga en curso.
  Future<List<Terceros>> download() async {
    if (_running) {
      throw TercerosDownloadException('Ya hay una descarga de terceros en curso');
    }
    _running = true;
    try {
      final stopwatchAPI = Stopwatch()..start();
      final apiTerceros = await _repository.fetAllTerceros(false);
      stopwatchAPI.stop();

      if (apiTerceros.isEmpty) {
        throw TercerosDownloadException('No se encontraron terceros en la nube');
      }

      final stopwatchDB = Stopwatch()..start();
      await _db.tercerosRepository.deleTerceros();
      await _db.tercerosRepository.insertTerceros(apiTerceros);
      stopwatchDB.stop();

      // ignore: avoid_print
      print(
        '⏱️ TERCEROS - API: ${stopwatchAPI.elapsedMilliseconds} ms, '
        'DB: ${stopwatchDB.elapsedMilliseconds} ms, '
        'guardados: ${apiTerceros.length}',
      );
      return apiTerceros;
    } finally {
      _running = false;
    }
  }
}

class TercerosDownloadException implements Exception {
  final String message;
  TercerosDownloadException(this.message);

  @override
  String toString() => message;
}
