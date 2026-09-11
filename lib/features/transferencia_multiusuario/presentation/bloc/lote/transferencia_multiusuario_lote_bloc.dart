import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_lote_producto.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/create_transferencia_lote_usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/fetch_transferencia_lotes_producto_usecase.dart';

part 'transferencia_multiusuario_lote_event.dart';
part 'transferencia_multiusuario_lote_state.dart';

/// Bloc de la pantalla "crear/seleccionar lote"
/// (TransferenciaMultiusuarioNewLoteScreen). Espejo de
/// RecepcionMultiusuarioLoteBloc: los lotes son un dato de producto, no de
/// sesión de transferencia, así que reusa los mismos endpoints genéricos
/// (GET /api/lotes/{productId}, POST /api/create_lote).
@injectable
class TransferenciaMultiusuarioLoteBloc
    extends
        Bloc<
          TransferenciaMultiusuarioLoteEvent,
          TransferenciaMultiusuarioLoteState
        > {
  final FetchTransferenciaLotesProductoUseCase
  fetchTransferenciaLotesProductoUseCase;
  final CreateTransferenciaLoteUseCase createTransferenciaLoteUseCase;

  List<TransferenciaLoteProducto> _todosLosLotes = [];

  TransferenciaMultiusuarioLoteBloc({
    required this.fetchTransferenciaLotesProductoUseCase,
    required this.createTransferenciaLoteUseCase,
  }) : super(const TransferenciaMultiusuarioLoteInitial()) {
    on<FetchTransferenciaLotesEvent>(_onFetchLotes);
    on<SearchTransferenciaLoteEvent>(_onSearchLote);
    on<CreateTransferenciaLoteEvent>(_onCreateLote);
  }

  Future<void> _onFetchLotes(
    FetchTransferenciaLotesEvent event,
    Emitter<TransferenciaMultiusuarioLoteState> emit,
  ) async {
    emit(const TransferenciaMultiusuarioLoteLoading());

    final result = await fetchTransferenciaLotesProductoUseCase(
      FetchTransferenciaLotesProductoParams(productId: event.productId),
    );

    result.fold(
      (failure) =>
          emit(TransferenciaMultiusuarioLoteError(_mapFailureMessage(failure))),
      (lotes) {
        _todosLosLotes = lotes;
        emit(TransferenciaLotesLoaded(_todosLosLotes));
      },
    );
  }

  void _onSearchLote(
    SearchTransferenciaLoteEvent event,
    Emitter<TransferenciaMultiusuarioLoteState> emit,
  ) {
    final query = event.query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _todosLosLotes
        : _todosLosLotes
              .where((l) => (l.name ?? '').toLowerCase().contains(query))
              .toList();
    emit(TransferenciaLotesLoaded(filtered));
  }

  Future<void> _onCreateLote(
    CreateTransferenciaLoteEvent event,
    Emitter<TransferenciaMultiusuarioLoteState> emit,
  ) async {
    emit(const CreateTransferenciaLoteLoading());

    final result = await createTransferenciaLoteUseCase(
      CreateTransferenciaLoteParams(
        productId: event.productId,
        nombreLote: event.nombreLote,
        fechaVencimiento: event.fechaVencimiento,
        priorityExpiration: event.priorityExpiration,
      ),
    );

    result.fold((failure) {
      if (failure is ConfirmationRequiredFailure) {
        emit(CreateTransferenciaLoteNeedsConfirmation(failure.message));
      } else {
        emit(CreateTransferenciaLoteError(_mapFailureMessage(failure)));
      }
    }, (lote) => emit(CreateTransferenciaLoteSuccess(lote)));
  }

  String _mapFailureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'Sin conexión a Internet',
      ServerFailure() => failure.message,
      _ => 'Error inesperado',
    };
  }
}
