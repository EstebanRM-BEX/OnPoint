import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';

/// Estado de una búsqueda paginada de ubicaciones para los blocs de las
/// pantallas de selección (Recepción, Transferencias, Conteo…): la página
/// cargada, si hay más, y la búsqueda vigente. Ver
/// docs/plan_ubicaciones_sqlite.md.
///
/// Cada [buscar] invalida las cargas anteriores: una página que llega tarde
/// (otra búsqueda ya empezó) se descarta en vez de mezclarse.
class PaginadorUbicaciones {
  PaginadorUbicaciones(this._repositorio, {this.tamanoPagina = 50});

  /// Función (no instancia) para que los tests puedan cambiar la base del
  /// bloc después de crearlo.
  final UbicacionesRepository Function() _repositorio;
  final int tamanoPagina;

  List<ResultUbicaciones> items = const [];
  bool hayMas = false;
  String query = '';
  FiltroUbicaciones filtro = FiltroUbicaciones.todas;
  int _generacion = 0;

  /// Sube con cada búsqueda aplicada (no al cargar más): las pantallas que
  /// guardan la selección por índice la descartan cuando cambia.
  int version = 0;

  /// Primera página de una búsqueda nueva. `false` si otra búsqueda la
  /// superó mientras consultaba (el resultado se descarta).
  Future<bool> buscar({
    String query = '',
    FiltroUbicaciones filtro = FiltroUbicaciones.todas,
  }) async {
    final generacion = ++_generacion;
    final pagina = await _repositorio().buscar(
      query: query,
      filtro: filtro,
      limit: tamanoPagina,
    );
    if (generacion != _generacion) return false;
    this.query = query;
    this.filtro = filtro;
    version++;
    items = pagina;
    hayMas = pagina.length == tamanoPagina;
    return true;
  }

  /// Agrega la página siguiente. `false` si no había más o si una búsqueda
  /// nueva empezó mientras consultaba.
  Future<bool> cargarMas() async {
    if (!hayMas) return false;
    final generacion = _generacion;
    final pagina = await _repositorio().buscar(
      query: query,
      filtro: filtro,
      limit: tamanoPagina,
      offset: items.length,
    );
    if (generacion != _generacion) return false;
    items = [...items, ...pagina];
    hayMas = pagina.length == tamanoPagina;
    return true;
  }

  /// Escaneo: ubicación por barcode (sin distinguir mayúsculas).
  Future<ResultUbicaciones?> porBarcode(String codigo) =>
      _repositorio().getByBarcode(codigo);

  /// Vacía la lista e invalida las cargas en curso.
  void reset() {
    _generacion++;
    version++;
    items = const [];
    hayMas = false;
    query = '';
    filtro = FiltroUbicaciones.todas;
  }
}
