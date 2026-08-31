import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/lote_producto.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/create_lote_usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/fetch_lotes_producto_usecase.dart';

part 'recepcion_multiusuario_lote_event.dart';
part 'recepcion_multiusuario_lote_state.dart';

/// Bloc de la pantalla "crear/seleccionar lote" (RecepcionMultiusuarioNewLoteScreen).
/// Los lotes son un dato de producto, no de sesión multiusuario, así que
/// reusa los mismos endpoints que recepción individual (GET
/// /api/lotes/{productId}, POST /api/create_lote) vía el mismo repositorio.
@injectable
class RecepcionMultiusuarioLoteBloc
    extends
        Bloc<RecepcionMultiusuarioLoteEvent, RecepcionMultiusuarioLoteState> {
  final FetchLotesProductoUseCase fetchLotesProductoUseCase;
  final CreateLoteUseCase createLoteUseCase;

  List<LoteProducto> _todosLosLotes = [];

  RecepcionMultiusuarioLoteBloc({
    required this.fetchLotesProductoUseCase,
    required this.createLoteUseCase,
  }) : super(const RecepcionMultiusuarioLoteInitial()) {
    on<FetchLotesEvent>(_onFetchLotes);
    on<SearchLoteEvent>(_onSearchLote);
    on<CreateLoteEvent>(_onCreateLote);
  }

  Future<void> _onFetchLotes(
    FetchLotesEvent event,
    Emitter<RecepcionMultiusuarioLoteState> emit,
  ) async {
    emit(const RecepcionMultiusuarioLoteLoading());

    final result = await fetchLotesProductoUseCase(
      FetchLotesProductoParams(productId: event.productId),
    );

    result.fold(
      (failure) =>
          emit(RecepcionMultiusuarioLoteError(_mapFailureMessage(failure))),
      (lotes) {
        _todosLosLotes = lotes;
        emit(RecepcionLotesLoaded(_todosLosLotes));
      },
    );
  }

  void _onSearchLote(
    SearchLoteEvent event,
    Emitter<RecepcionMultiusuarioLoteState> emit,
  ) {
    final query = event.query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _todosLosLotes
        : _todosLosLotes
              .where((l) => (l.name ?? '').toLowerCase().contains(query))
              .toList();
    emit(RecepcionLotesLoaded(filtered));
  }

  Future<void> _onCreateLote(
    CreateLoteEvent event,
    Emitter<RecepcionMultiusuarioLoteState> emit,
  ) async {
    emit(const CreateLoteLoading());

    final result = await createLoteUseCase(
      CreateLoteParams(
        productId: event.productId,
        nombreLote: event.nombreLote,
        fechaVencimiento: event.fechaVencimiento,
        priorityExpiration: event.priorityExpiration,
      ),
    );

    result.fold((failure) {
      if (failure is ConfirmationRequiredFailure) {
        emit(CreateLoteNeedsConfirmation(failure.message));
      } else {
        emit(CreateLoteError(_mapFailureMessage(failure)));
      }
    }, (lote) => emit(CreateLoteSuccess(lote)));
  }

  String _mapFailureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'Sin conexión a Internet',
      ServerFailure() => failure.message,
      _ => 'Error inesperado',
    };
  }
}
