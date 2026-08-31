import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

part 'recepcion_multiusuario_location_dest_event.dart';
part 'recepcion_multiusuario_location_dest_state.dart';

/// Bloc de la pantalla "buscar ubicación destino"
/// (RecepcionMultiusuarioLocationDestScreen). Las ubicaciones son una tabla
/// local genérica ya sincronizada (tbl_ubicaciones), compartida por varios
/// módulos de la app — no hay endpoint nuevo, se lee directo de
/// DataBaseSqlite().ubicacionesRepository, igual que hace RecepcionBloc
/// (recepción individual) para la misma pantalla de referencia.
@injectable
class RecepcionMultiusuarioLocationDestBloc
    extends
        Bloc<
          RecepcionMultiusuarioLocationDestEvent,
          RecepcionMultiusuarioLocationDestState
        > {
  List<ResultUbicaciones> _todasLasUbicaciones = [];
  String _query = '';

  // null = todos los almacenes. Se expone como getter (no como parte del
  // state) porque solo es texto/filtro de UI, mismo patrón que
  // bloc.selectedAlmacen en recepción individual.
  String? _selectedAlmacen;
  String? get selectedAlmacen => _selectedAlmacen;

  RecepcionMultiusuarioLocationDestBloc()
    : super(const RecepcionMultiusuarioLocationDestInitial()) {
    on<FetchUbicacionesDestEvent>(_onFetchUbicaciones);
    on<SearchUbicacionDestEvent>(_onSearchUbicacion);
    on<FilterUbicacionesAlmacenEvent>(_onFilterAlmacen);
  }

  Future<void> _onFetchUbicaciones(
    FetchUbicacionesDestEvent event,
    Emitter<RecepcionMultiusuarioLocationDestState> emit,
  ) async {
    // El bloc vive a nivel de app (BlocProvider raíz en main.dart), así que
    // esta caché sobrevive a que se entre y salga de la pantalla. tbl_
    // ubicaciones no cambia durante la sesión (se sincroniza aparte), así
    // que solo hace falta consultarla una vez — si no, cada reingreso
    // repite la consulta completa y muestra el loading de nuevo sin razón.
    if (_todasLasUbicaciones.isNotEmpty) {
      emit(RecepcionMultiusuarioLocationDestLoaded(_filtradas()));
      return;
    }

    emit(const RecepcionMultiusuarioLocationDestLoading());
    try {
      _todasLasUbicaciones = await DataBaseSqlite().ubicacionesRepository
          .getAllUbicaciones();
      emit(RecepcionMultiusuarioLocationDestLoaded(_filtradas()));
    } catch (_) {
      emit(
        const RecepcionMultiusuarioLocationDestError(
          'No se pudieron cargar las ubicaciones',
        ),
      );
    }
  }

  void _onSearchUbicacion(
    SearchUbicacionDestEvent event,
    Emitter<RecepcionMultiusuarioLocationDestState> emit,
  ) {
    _query = event.query.trim().toLowerCase();
    emit(RecepcionMultiusuarioLocationDestLoaded(_filtradas()));
  }

  void _onFilterAlmacen(
    FilterUbicacionesAlmacenEvent event,
    Emitter<RecepcionMultiusuarioLocationDestState> emit,
  ) {
    _selectedAlmacen = event.almacen;
    emit(RecepcionMultiusuarioLocationDestLoaded(_filtradas()));
  }

  /// Combina el filtro por almacén (menú del appbar) con la búsqueda por
  /// texto — ambos aplican a la vez, igual que en recepción individual.
  List<ResultUbicaciones> _filtradas() {
    Iterable<ResultUbicaciones> ubicaciones = _todasLasUbicaciones;

    final almacen = _selectedAlmacen;
    if (almacen != null && almacen.isNotEmpty) {
      ubicaciones = ubicaciones.where((u) => u.warehouseName == almacen);
    }

    if (_query.isNotEmpty) {
      ubicaciones = ubicaciones.where(
        (u) =>
            (u.name ?? '').toLowerCase().contains(_query) ||
            (u.barcode ?? '').toLowerCase().contains(_query),
      );
    }

    return ubicaciones.toList();
  }
}
