import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/fetch_recepcion_pool_usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/get_recepcion_pool_from_db_usecase.dart';

part 'recepcion_multiusuario_pool_event.dart';
part 'recepcion_multiusuario_pool_state.dart';

/// Bloc del pool de una sesión de recepción multiusuario
/// (POST /api/receipt/session/{id}/pool). Un solo bloc alimenta dos vistas
/// con datos DISTINTOS del mismo endpoint, según el flag `verification`:
///   - "Por hacer" (verification: false): solo lo realmente disponible.
///   - "Terminados" (verification: true): incluye tareas agotadas
///     (qty_available: 0) que ya tienen historial de asignaciones —
///     confirmado que sin el flag esas tareas no vienen en la respuesta.
///
/// Como son datasets distintos que se refrescan en momentos distintos,
/// [poolItems]/[terminadosItems] guardan cada uno su última copia cargada
/// (mismo patrón que RecepcionMultiusuarioMyClaimsBloc.currentClaims): la
/// UI siempre lee de ahí, nunca de `state.items` directo, para que un
/// fetch de una vista no "vacíe" momentáneamente lo que ya tenía cargado
/// la otra.
@injectable
class RecepcionMultiusuarioPoolBloc
    extends
        Bloc<RecepcionMultiusuarioPoolEvent, RecepcionMultiusuarioPoolState> {
  final FetchRecepcionPoolUseCase fetchRecepcionPoolUseCase;
  final GetRecepcionPoolFromDbUseCase getRecepcionPoolFromDbUseCase;

  /// Última copia cargada con verification: false — tab "Por hacer".
  List<RecepcionPoolItem> poolItems = [];

  /// Última copia cargada con verification: true — tab "Terminados".
  List<RecepcionPoolItem> terminadosItems = [];

  RecepcionMultiusuarioPoolBloc({
    required this.fetchRecepcionPoolUseCase,
    required this.getRecepcionPoolFromDbUseCase,
  }) : super(const RecepcionMultiusuarioPoolInitial()) {
    on<FetchRecepcionPoolEvent>(_onFetchPool);
    on<FetchRecepcionPoolFromDbEvent>(_onFetchPoolFromDb);
  }

  Future<void> _onFetchPool(
    FetchRecepcionPoolEvent event,
    Emitter<RecepcionMultiusuarioPoolState> emit,
  ) async {
    emit(RecepcionMultiusuarioPoolLoading(event.verification));

    final result = await fetchRecepcionPoolUseCase(
      FetchRecepcionPoolParams(
        sessionId: event.sessionId,
        isLoadinDialog: event.isLoadinDialog,
        verification: event.verification,
      ),
    );

    result.fold(
      (failure) => emit(
        RecepcionMultiusuarioPoolError(
          _mapFailureMessage(failure),
          event.verification,
        ),
      ),
      (items) {
        if (event.verification) {
          terminadosItems = items;
        } else {
          poolItems = items;
        }
        emit(RecepcionPoolLoaded(items, event.verification));
      },
    );
  }

  Future<void> _onFetchPoolFromDb(
    FetchRecepcionPoolFromDbEvent event,
    Emitter<RecepcionMultiusuarioPoolState> emit,
  ) async {
    emit(const RecepcionMultiusuarioPoolDbLoading());

    final result = await getRecepcionPoolFromDbUseCase(
      GetRecepcionPoolFromDbParams(sessionId: event.sessionId),
    );

    result.fold(
      (failure) => emit(
        RecepcionMultiusuarioPoolError(_mapFailureMessage(failure), false),
      ),
      (items) {
        poolItems = items;
        emit(RecepcionPoolLoaded(items, false));
      },
    );
  }

  String _mapFailureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'Sin conexión a Internet',
      ServerFailure() => failure.message,
      CacheFailure() => 'Error al leer datos locales',
      _ => 'Error inesperado',
    };
  }
}
