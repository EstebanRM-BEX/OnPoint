import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/lote_producto.dart';
import '../../../domain/usecases/crear_lote_producto_use_case.dart';
import '../../../domain/usecases/get_lotes_producto_use_case.dart';

part 'lote_producto_event.dart';
part 'lote_producto_state.dart';

@injectable
class LoteProductoBloc extends Bloc<LoteProductoEvent, LoteProductoState> {
  final GetLotesProductoUseCase getLotesProductoUseCase;
  final CrearLoteProductoUseCase crearLoteProductoUseCase;

  LoteProductoBloc({
    required this.getLotesProductoUseCase,
    required this.crearLoteProductoUseCase,
  }) : super(LoteProductoInitial()) {
    on<FetchLotesProductoEvent>(_onFetchLotesProducto);
    on<CrearLoteProductoEvent>(_onCrearLoteProducto);
  }

  Future<void> _onFetchLotesProducto(
    FetchLotesProductoEvent event,
    Emitter<LoteProductoState> emit,
  ) async {
    emit(LoteProductoLoading());

    final result = await getLotesProductoUseCase(
      GetLotesProductoParams(productId: event.productId),
    );

    result.fold(
      (failure) => emit(LoteProductoError(failure.message)),
      (lotes) => emit(LotesProductoLoaded(lotes)),
    );
  }

  Future<void> _onCrearLoteProducto(
    CrearLoteProductoEvent event,
    Emitter<LoteProductoState> emit,
  ) async {
    emit(LoteProductoLoading());

    final result = await crearLoteProductoUseCase(
      CrearLoteProductoParams(
        productId: event.productId,
        name: event.name,
        expirationDate: event.expirationDate,
      ),
    );

    result.fold(
      (failure) => emit(LoteProductoError(failure.message)),
      (lote) => emit(LoteProductoCreated(lote)),
    );
  }
}
