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

  RecepcionMultiusuarioLocationDestBloc()
    : super(const RecepcionMultiusuarioLocationDestInitial()) {
    on<FetchUbicacionesDestEvent>(_onFetchUbicaciones);
    on<SearchUbicacionDestEvent>(_onSearchUbicacion);
  }

  Future<void> _onFetchUbicaciones(
    FetchUbicacionesDestEvent event,
    Emitter<RecepcionMultiusuarioLocationDestState> emit,
  ) async {
    emit(const RecepcionMultiusuarioLocationDestLoading());
    try {
      _todasLasUbicaciones = await DataBaseSqlite().ubicacionesRepository
          .getAllUbicaciones();
      emit(RecepcionMultiusuarioLocationDestLoaded(_todasLasUbicaciones));
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
    final query = event.query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _todasLasUbicaciones
        : _todasLasUbicaciones
              .where(
                (u) =>
                    (u.name ?? '').toLowerCase().contains(query) ||
                    (u.barcode ?? '').toLowerCase().contains(query),
              )
              .toList();
    emit(RecepcionMultiusuarioLocationDestLoaded(filtered));
  }
}
