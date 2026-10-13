import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/paginador_ubicaciones.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';

part 'recepcion_multiusuario_location_dest_event.dart';
part 'recepcion_multiusuario_location_dest_state.dart';

/// Bloc de la pantalla "buscar ubicación destino"
/// (RecepcionMultiusuarioLocationDestScreen). Las ubicaciones (tbl_ubicaciones,
/// hasta ~19 mil por cliente) se consultan en SQLite por página: filtro por
/// almacén y búsqueda por texto se aplican a la vez. Ver
/// docs/plan_ubicaciones_sqlite.md.
@injectable
class RecepcionMultiusuarioLocationDestBloc
    extends
        Bloc<
          RecepcionMultiusuarioLocationDestEvent,
          RecepcionMultiusuarioLocationDestState
        > {
  /// Repositorio de ubicaciones (los tests lo reemplazan).
  @visibleForTesting
  UbicacionesRepository Function() repositorio = () =>
      DataBaseSqlite().ubicacionesRepository;

  late final PaginadorUbicaciones _paginador = PaginadorUbicaciones(
    () => repositorio(),
  );
  String _query = '';

  // null = todos los almacenes. Se expone como getter (no como parte del
  // state) porque solo es texto/filtro de UI, mismo patrón que
  // bloc.selectedAlmacen en recepción individual.
  String? _selectedAlmacen;
  String? get selectedAlmacen => _selectedAlmacen;

  RecepcionMultiusuarioLocationDestBloc()
    : super(const RecepcionMultiusuarioLocationDestInitial()) {
    on<FetchUbicacionesDestEvent>(_onFetchUbicaciones);
    // restartable: cada tecla o filtro cancela la búsqueda anterior.
    on<SearchUbicacionDestEvent>(
      _onSearchUbicacion,
      transformer: restartable(),
    );
    on<FilterUbicacionesAlmacenEvent>(
      _onFilterAlmacen,
      transformer: restartable(),
    );
    on<LoadMoreUbicacionesDestEvent>(
      _onLoadMore,
      transformer: droppable(),
    );
  }

  FiltroUbicaciones get _filtro {
    final almacen = _selectedAlmacen;
    return almacen == null || almacen.isEmpty
        ? FiltroUbicaciones.todas
        : FiltroUbicaciones(warehouseName: almacen);
  }

  RecepcionMultiusuarioLocationDestLoaded get _loaded =>
      RecepcionMultiusuarioLocationDestLoaded(
        _paginador.items,
        hayMas: _paginador.hayMas,
        version: _paginador.version,
      );

  Future<void> _onFetchUbicaciones(
    FetchUbicacionesDestEvent event,
    Emitter<RecepcionMultiusuarioLocationDestState> emit,
  ) async {
    emit(const RecepcionMultiusuarioLocationDestLoading());
    try {
      await _paginador.buscar(query: _query, filtro: _filtro);
      emit(_loaded);
    } catch (_) {
      emit(
        const RecepcionMultiusuarioLocationDestError(
          'No se pudieron cargar las ubicaciones',
        ),
      );
    }
  }

  Future<void> _onSearchUbicacion(
    SearchUbicacionDestEvent event,
    Emitter<RecepcionMultiusuarioLocationDestState> emit,
  ) async {
    _query = event.query.trim();
    // Debounce: si llega otra tecla, restartable cierra este emitter.
    if (_query.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (emit.isDone) return;
    }
    if (await _paginador.buscar(query: _query, filtro: _filtro) &&
        !emit.isDone) {
      emit(_loaded);
    }
  }

  Future<void> _onFilterAlmacen(
    FilterUbicacionesAlmacenEvent event,
    Emitter<RecepcionMultiusuarioLocationDestState> emit,
  ) async {
    _selectedAlmacen = event.almacen;
    if (await _paginador.buscar(query: _query, filtro: _filtro) &&
        !emit.isDone) {
      emit(_loaded);
    }
  }

  Future<void> _onLoadMore(
    LoadMoreUbicacionesDestEvent event,
    Emitter<RecepcionMultiusuarioLocationDestState> emit,
  ) async {
    if (await _paginador.cargarMas()) emit(_loaded);
  }
}
