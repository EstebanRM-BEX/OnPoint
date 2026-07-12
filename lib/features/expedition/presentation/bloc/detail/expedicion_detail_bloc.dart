import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/features/expedition/domain/usecases/get_expedicion_detail_usecase.dart';

part 'expedicion_detail_event.dart';
part 'expedicion_detail_state.dart';

/// Bloc separado solo para cargar el detalle (solo lectura) de una
/// expedición: pedido + paquetes + items sueltos ya sincronizados en SQLite.
@injectable
class ExpedicionDetailBloc
    extends Bloc<ExpedicionDetailEvent, ExpedicionDetailState> {
  final GetExpedicionDetailUseCase getExpedicionDetailUseCase;

  ExpedicionDetailBloc({required this.getExpedicionDetailUseCase})
      : super(const ExpedicionDetailInitial()) {
    on<LoadExpedicionDetailEvent>(_onLoadExpedicionDetail);
  }

  Future<void> _onLoadExpedicionDetail(
    LoadExpedicionDetailEvent event,
    Emitter<ExpedicionDetailState> emit,
  ) async {
    emit(const ExpedicionDetailLoading());

    final result = await getExpedicionDetailUseCase(
      GetExpedicionDetailParams(expeditionId: event.expeditionId),
    );

    result.fold(
      (failure) => emit(ExpedicionDetailError(failure.message)),
      (detail) => emit(ExpedicionDetailLoaded(detail)),
    );
  }
}
