import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

part 'transferencia_multiusuario_location_dest_event.dart';
part 'transferencia_multiusuario_location_dest_state.dart';

/// Bloc de la pantalla "buscar ubicación destino"
/// (TransferenciaMultiusuarioLocationDestScreen). Espejo de
/// RecepcionMultiusuarioLocationDestBloc: las ubicaciones son una tabla
/// local genérica ya sincronizada (tbl_ubicaciones), compartida por varios
/// módulos — no hay endpoint nuevo, se lee directo de
/// DataBaseSqlite().ubicacionesRepository.
@injectable
class TransferenciaMultiusuarioLocationDestBloc
    extends
        Bloc<
          TransferenciaMultiusuarioLocationDestEvent,
          TransferenciaMultiusuarioLocationDestState
        > {
  List<ResultUbicaciones> _todasLasUbicaciones = [];
  String _query = '';

  // null = todos los almacenes. Se expone como getter (no como parte del
  // state) porque solo es texto/filtro de UI, mismo patrón que
  // RecepcionMultiusuarioLocationDestBloc.selectedAlmacen.
  String? _selectedAlmacen;
  String? get selectedAlmacen => _selectedAlmacen;

  TransferenciaMultiusuarioLocationDestBloc()
    : super(const TransferenciaMultiusuarioLocationDestInitial()) {
    on<FetchTransferenciaUbicacionesDestEvent>(_onFetchUbicaciones);
    on<SearchTransferenciaUbicacionDestEvent>(_onSearchUbicacion);
    on<FilterTransferenciaUbicacionesAlmacenEvent>(_onFilterAlmacen);
  }

  Future<void> _onFetchUbicaciones(
    FetchTransferenciaUbicacionesDestEvent event,
    Emitter<TransferenciaMultiusuarioLocationDestState> emit,
  ) async {
    // El bloc vive a nivel de app (BlocProvider raíz en main.dart), así que
    // esta caché sobrevive a que se entre y salga de la pantalla — tbl_
    // ubicaciones no cambia durante la sesión.
    if (_todasLasUbicaciones.isNotEmpty) {
      emit(TransferenciaMultiusuarioLocationDestLoaded(_filtradas()));
      return;
    }

    emit(const TransferenciaMultiusuarioLocationDestLoading());
    try {
      _todasLasUbicaciones = await DataBaseSqlite().ubicacionesRepository
          .getAllUbicaciones();
      emit(TransferenciaMultiusuarioLocationDestLoaded(_filtradas()));
    } catch (_) {
      emit(
        const TransferenciaMultiusuarioLocationDestError(
          'No se pudieron cargar las ubicaciones',
        ),
      );
    }
  }

  void _onSearchUbicacion(
    SearchTransferenciaUbicacionDestEvent event,
    Emitter<TransferenciaMultiusuarioLocationDestState> emit,
  ) {
    _query = event.query.trim().toLowerCase();
    emit(TransferenciaMultiusuarioLocationDestLoaded(_filtradas()));
  }

  void _onFilterAlmacen(
    FilterTransferenciaUbicacionesAlmacenEvent event,
    Emitter<TransferenciaMultiusuarioLocationDestState> emit,
  ) {
    _selectedAlmacen = event.almacen;
    emit(TransferenciaMultiusuarioLocationDestLoaded(_filtradas()));
  }

  /// Combina el filtro por almacén (menú del appbar) con la búsqueda por
  /// texto — ambos aplican a la vez.
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
