import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';
import 'package:wms_app/features/expedition/domain/usecases/asignar_responsable_usecase.dart';

part 'expedicion_assignment_event.dart';
part 'expedicion_assignment_state.dart';

/// Bloc separado solo para asignar responsable + iniciar tiempo de una
/// expedición — no maneja lista ni detalle, esas responsabilidades viven en
/// ExpedicionListBloc y ExpedicionDetailBloc respectivamente.
@injectable
class ExpedicionAssignmentBloc
    extends Bloc<ExpedicionAssignmentEvent, ExpedicionAssignmentState> {
  final AsignarResponsableUseCase asignarResponsableUseCase;

  ExpedicionAssignmentBloc({required this.asignarResponsableUseCase})
      : super(const ExpedicionAssignmentInitial()) {
    on<AsignarResponsableEvent>(_onAsignarResponsable);
  }

  Future<void> _onAsignarResponsable(
    AsignarResponsableEvent event,
    Emitter<ExpedicionAssignmentState> emit,
  ) async {
    emit(const ExpedicionAssignmentLoading());

    final result = await asignarResponsableUseCase(
      AsignarResponsableParams(expeditionId: event.expeditionId),
    );

    result.fold(
      (failure) => emit(ExpedicionAssignmentError(failure.message)),
      (pedido) => emit(ExpedicionAssignmentSuccess(pedido)),
    );
  }
}
