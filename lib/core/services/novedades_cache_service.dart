import 'dart:collection';

import 'package:injectable/injectable.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

/// Cache en memoria de las novedades (tbl_novedades), compartido por toda la
/// app. Mismo problema que Ubicaciones/ProductosCacheService: ~9 blocs
/// (RecepcionBloc, RecepcionBatchBloc, TransferenciaBloc, WMSPickingBloc,
/// WmsPackingBloc, PackingConsolidadeBloc, PackingPedidoBloc, BatchBloc,
/// PickingPickBloc) hacían su propia consulta a `novedadesRepository.
/// getAllNovedades()` y guardaban su propia copia completa, para siempre.
///
/// tbl_novedades ya se sincroniza desde un solo lugar (UserBloc.
/// DownloadNoveltiesEvent / user_local_data_source.dart:syncNovedades, que
/// escribe ahí mismo después de bajar `picking_novelties` por red) — este
/// cache solo evita que cada bloc vuelva a leer esa misma tabla por su
/// cuenta y guarde su propia copia en memoria.
@lazySingleton
class NovedadesCacheService {
  List<Novedad>? _cache;

  Future<List<Novedad>> getAll({bool forceRefresh = false}) async {
    // No memoizar un resultado vacío: la sincronización de novedades en
    // background (post-login, fire-and-forget) puede no haber terminado
    // todavía, o el repositorio puede haber atrapado un error transitorio
    // de SQLite — cachear eso lo deja "vacío para siempre" aunque la data
    // real ya esté disponible en la siguiente consulta.
    if (_cache == null || _cache!.isEmpty || forceRefresh) {
      _cache = await DataBaseSqlite().novedadesRepository.getAllNovedades();
    }
    // Una sola lista para toda la app: todos los consumidores reasignan
    // directo (`novedades = response;`), nunca mutan la lista in-place.
    // UnmodifiableListView es una vista (no copia el arreglo interno: sigue
    // siendo LA MISMA lista para todos) y convierte cualquier intento
    // futuro de `.clear()/.sort()/.add()` en un UnsupportedError inmediato
    // en vez de corromper el cache en silencio.
    return UnmodifiableListView(_cache!);
  }

  /// Recarga desde SQLite — usar tras una sincronización manual de
  /// novedades (UserBloc.DownloadNoveltiesEvent).
  Future<List<Novedad>> refresh() => getAll(forceRefresh: true);

  void invalidate() => _cache = null;
}
