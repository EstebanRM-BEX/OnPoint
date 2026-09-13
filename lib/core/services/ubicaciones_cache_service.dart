import 'dart:collection';

import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

/// Cache en memoria del catálogo de ubicaciones (tbl_ubicaciones), compartido
/// por toda la app. Antes cada bloc (RecepcionBloc, TransferenciaBloc,
/// WMSPickingBloc, BatchBloc, ConteoBloc, DevolucionesBloc, InfoRapidaBloc,
/// TransferInfoBloc, CreateTransferBloc, PrintLabelsBloc — 10 en total) hacía
/// su propia llamada a `ubicacionesRepository.getAllUbicaciones()` y guardaba
/// su propia copia de la lista completa en memoria, para siempre (todos esos
/// blocs viven en el MultiBlocProvider raíz y nunca se disponen). En un
/// almacén con miles de ubicaciones, eso son varias copias idénticas
/// simultáneas en RAM apenas el operario toca 2-3 módulos en el mismo turno.
///
/// [getAll] memoiza el resultado — el primer llamador paga el costo de la
/// consulta SQLite, el resto reusa la misma lista en memoria. [invalidate]/
/// [refresh] se llaman desde los eventos de sincronización manual
/// (ej. "Descargar novedades y ubicaciones" del perfil, DownloadLocationsEvent)
/// para no dejar el cache con datos viejos tras una descarga explícita.
@lazySingleton
class UbicacionesCacheService {
  List<ResultUbicaciones>? _cache;

  /// true si ya hay datos en memoria (sin necesidad de esperar el Future) —
  /// útil para blocs que hoy exponen la lista como campo público síncrono.
  bool get isLoaded => _cache != null && _cache!.isNotEmpty;

  /// Última copia cargada, o vacía si [getAll] todavía no se llamó ninguna
  /// vez. Acceso síncrono para el mismo patrón que ya usan los blocs
  /// existentes (leer `bloc.ubicaciones` directo, sin await).
  List<ResultUbicaciones> get current => _cache ?? const [];

  Future<List<ResultUbicaciones>> getAll({bool forceRefresh = false}) async {
    // No memoizar un resultado vacío: la sincronización de ubicaciones en
    // background (post-login, fire-and-forget) puede no haber terminado
    // todavía cuando llega la primera consulta, o el repositorio puede
    // haber atrapado un error transitorio de SQLite y devuelto [] — cachear
    // eso lo deja "vacío para siempre" aunque el catálogo real ya esté
    // disponible en la siguiente consulta (bug real visto en
    // ProductosCacheService: "Crear Devolución" quedaba sin productos).
    if (_cache == null || _cache!.isEmpty || forceRefresh) {
      _cache = await DataBaseSqlite().ubicacionesRepository.getAllUbicaciones();
    }
    // Una sola lista para toda la app: se auditó cada consumidor y se quitó
    // el idioma `campo.clear(); if(...) campo = response;` que antes hacía
    // falta copiar para evitar (ese clear() vaciaba el cache compartido Y la
    // variable local de la misma invocación, al ser el mismo objeto — bug
    // real confirmado en ProductosCacheService). Ahora todos los
    // consumidores reasignan su campo directo (`campo = response;`), nunca
    // mutan la lista recibida in-place — así que ya no hace falta copiar en
    // cada llamada. UnmodifiableListView es una vista (no copia el arreglo
    // interno: sigue siendo LA MISMA lista para todos), y convierte
    // cualquier intento futuro de `.clear()/.sort()/.add()` en un
    // UnsupportedError inmediato en vez de corromper el cache en silencio.
    return UnmodifiableListView(_cache!);
  }

  /// Fuerza una recarga inmediata desde SQLite y actualiza el cache — usar
  /// tras una sincronización manual (el operario descargó ubicaciones
  /// nuevas y el cache en memoria quedaría desactualizado si no se refresca).
  Future<List<ResultUbicaciones>> refresh() => getAll(forceRefresh: true);

  /// Descarta el cache sin recargar — el próximo [getAll] vuelve a consultar
  /// SQLite. Útil al cerrar sesión (evita que la próxima sesión arranque
  /// mostrando ubicaciones de otro usuario/almacén si algún día esto deja de
  /// ser un catálogo global).
  void invalidate() => _cache = null;
}
