import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_pool_item.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/fetch_transferencia_pool_usecase.dart';

part 'transferencia_multiusuario_pool_event.dart';
part 'transferencia_multiusuario_pool_state.dart';

/// Bloc del pool de una sesión de transferencia multiusuario
/// (POST /api/transfer/session/{id}/pool). Espejo de
/// RecepcionMultiusuarioPoolBloc: un solo bloc alimenta dos vistas con datos
/// DISTINTOS del mismo endpoint, según el flag `verification`:
///   - "Por hacer" (verification: false): solo lo realmente disponible.
///   - "Terminados" (verification: true): incluye tareas agotadas.
///
/// A diferencia de recepción, acá NO hay caché local (getPoolFromDb): se
/// confirmó que esa caché existe en recepción pero nunca se usa — el pool
/// es en vivo y siempre se pide fresco al backend.
///
/// [poolItems]/[terminadosItems] guardan cada uno su última copia cargada
/// (mismo patrón que RecepcionMultiusuarioPoolBloc): la UI siempre lee de
/// ahí, nunca de `state.items` directo.
@injectable
class TransferenciaMultiusuarioPoolBloc
    extends
        Bloc<
          TransferenciaMultiusuarioPoolEvent,
          TransferenciaMultiusuarioPoolState
        > {
  final FetchTransferenciaPoolUseCase fetchTransferenciaPoolUseCase;

  /// Última copia cargada con verification: false — tab "Por hacer".
  List<TransferenciaPoolItem> poolItems = [];

  /// Última copia cargada con verification: true — tab "Terminados".
  List<TransferenciaPoolItem> terminadosItems = [];

  TransferenciaMultiusuarioPoolBloc({
    required this.fetchTransferenciaPoolUseCase,
  }) : super(const TransferenciaMultiusuarioPoolInitial()) {
    on<FetchTransferenciaPoolEvent>(_onFetchPool);
    on<SeedTransferenciaTerminadosEvent>(_onSeedTerminados);
  }

  Future<void> _onFetchPool(
    FetchTransferenciaPoolEvent event,
    Emitter<TransferenciaMultiusuarioPoolState> emit,
  ) async {
    emit(TransferenciaMultiusuarioPoolLoading(event.verification));

    final result = await fetchTransferenciaPoolUseCase(
      FetchTransferenciaPoolParams(
        sessionId: event.sessionId,
        isLoadinDialog: event.isLoadinDialog,
        verification: event.verification,
      ),
    );

    result.fold(
      (failure) => emit(
        TransferenciaMultiusuarioPoolError(
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
        emit(TransferenciaPoolLoaded(items, event.verification));
      },
    );
  }

  void _onSeedTerminados(
    SeedTransferenciaTerminadosEvent event,
    Emitter<TransferenciaMultiusuarioPoolState> emit,
  ) {
    terminadosItems = event.items;
    emit(TransferenciaPoolLoaded(event.items, true));
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
