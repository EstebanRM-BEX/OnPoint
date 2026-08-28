import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/fetch_recepcion_pool_usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/get_recepcion_pool_from_db_usecase.dart';

part 'recepcion_multiusuario_pool_event.dart';
part 'recepcion_multiusuario_pool_state.dart';

/// Bloc del pool de productos libres de una sesión de recepción multiusuario
/// (POST /api/receipt/session/{id}/pool). Se va a llamar muy seguido —cada
/// vez que hay que saber qué quedó libre y qué ya tomó otro operario— así
/// que cada fetch reemplaza por completo el pool local de la sesión.
@injectable
class RecepcionMultiusuarioPoolBloc
    extends
        Bloc<RecepcionMultiusuarioPoolEvent, RecepcionMultiusuarioPoolState> {
  final FetchRecepcionPoolUseCase fetchRecepcionPoolUseCase;
  final GetRecepcionPoolFromDbUseCase getRecepcionPoolFromDbUseCase;

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
    emit(const RecepcionMultiusuarioPoolLoading());

    final result = await fetchRecepcionPoolUseCase(
      FetchRecepcionPoolParams(
        sessionId: event.sessionId,
        isLoadinDialog: event.isLoadinDialog,
      ),
    );

    result.fold(
      (failure) =>
          emit(RecepcionMultiusuarioPoolError(_mapFailureMessage(failure))),
      (items) => emit(RecepcionPoolLoaded(items)),
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
      (failure) =>
          emit(RecepcionMultiusuarioPoolError(_mapFailureMessage(failure))),
      (items) => emit(RecepcionPoolLoaded(items)),
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
