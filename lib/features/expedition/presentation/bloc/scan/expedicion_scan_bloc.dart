import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';
import 'package:wms_app/features/expedition/domain/usecases/deshacer_item_suelto_usecase.dart';
import 'package:wms_app/features/expedition/domain/usecases/deshacer_paquete_usecase.dart';
import 'package:wms_app/features/expedition/domain/usecases/validar_item_suelto_usecase.dart';
import 'package:wms_app/features/expedition/domain/usecases/validar_multiple_usecase.dart';
import 'package:wms_app/features/expedition/domain/usecases/validar_paquete_usecase.dart';

part 'expedicion_scan_event.dart';
part 'expedicion_scan_state.dart';

/// Bloc compartido para validar (scan_product_screen) y deshacer (tab
/// "Listo") un paquete o producto suelto de una expedición: llama al backend
/// (por ahora simulado, ver ExpeditionRemoteDataSourceImpl) y, si responde
/// ok, actualiza is_validate en SQLite para mover el ítem entre "Por hacer"
/// y "Listo".
@injectable
class ExpedicionScanBloc extends Bloc<ExpedicionScanEvent, ExpedicionScanState> {
  final ValidarPaqueteUseCase validarPaqueteUseCase;
  final ValidarItemSueltoUseCase validarItemSueltoUseCase;
  final ValidarMultipleUseCase validarMultipleUseCase;
  final DeshacerPaqueteUseCase deshacerPaqueteUseCase;
  final DeshacerItemSueltoUseCase deshacerItemSueltoUseCase;

  ExpedicionScanBloc({
    required this.validarPaqueteUseCase,
    required this.validarItemSueltoUseCase,
    required this.validarMultipleUseCase,
    required this.deshacerPaqueteUseCase,
    required this.deshacerItemSueltoUseCase,
  }) : super(const ExpedicionScanInitial()) {
    on<ValidarExpedicionScanEvent>(_onValidar);
    on<ValidarMultipleExpedicionScanEvent>(_onValidarMultiple);
    on<DeshacerExpedicionScanEvent>(_onDeshacer);
  }

  Future<void> _onValidarMultiple(
    ValidarMultipleExpedicionScanEvent event,
    Emitter<ExpedicionScanState> emit,
  ) async {
    // Los ítems sin packingId no se pueden mandar al backend: los descartamos
    // acá para no enviar 0 y validar algo que no es.
    final idsPaquetes = event.paquetes
        .map((p) => p.packingId)
        .whereType<int>()
        .toList();
    final idsItemsSueltos = event.itemsSueltos
        .map((i) => i.packingId)
        .whereType<int>()
        .toList();

    if (idsPaquetes.isEmpty && idsItemsSueltos.isEmpty) {
      emit(const ExpedicionScanErrorMultiple(
          'La selección no tiene elementos válidos'));
      return;
    }

    emit(const ExpedicionScanValidatingMultiple());

    final result = await validarMultipleUseCase(ValidarMultipleParams(
      expeditionId: event.expeditionId,
      packingIdsPaquetes: idsPaquetes,
      packingIdsItemsSueltos: idsItemsSueltos,
    ));

    result.fold(
      (failure) => emit(ExpedicionScanErrorMultiple(failure.message)),
      (_) => emit(ExpedicionScanValidatedMultiple(
          idsPaquetes.length + idsItemsSueltos.length)),
    );
  }

  Future<void> _onValidar(
    ValidarExpedicionScanEvent event,
    Emitter<ExpedicionScanState> emit,
  ) async {
    emit(const ExpedicionScanValidating());

    if (event.paquete != null) {
      final paquete = event.paquete!;
      final result = await validarPaqueteUseCase(ValidarPaqueteParams(
        expeditionId: paquete.expeditionId ?? 0,
        packingId: paquete.packingId ?? 0,
      ));
      result.fold(
        (failure) => emit(ExpedicionScanError(failure.message)),
        (_) => emit(const ExpedicionScanValidated()),
      );
      return;
    }

    if (event.itemSuelto != null) {
      final item = event.itemSuelto!;
      final result = await validarItemSueltoUseCase(ValidarItemSueltoParams(
        expeditionId: item.expeditionId ?? 0,
        packingId: item.packingId ?? 0,
      ));
      result.fold(
        (failure) => emit(ExpedicionScanError(failure.message)),
        (_) => emit(const ExpedicionScanValidated()),
      );
    }
  }

  Future<void> _onDeshacer(
    DeshacerExpedicionScanEvent event,
    Emitter<ExpedicionScanState> emit,
  ) async {
    emit(const ExpedicionScanUndoing());

    if (event.paquete != null) {
      final paquete = event.paquete!;
      final result = await deshacerPaqueteUseCase(DeshacerPaqueteParams(
        expeditionId: paquete.expeditionId ?? 0,
        packingId: paquete.packingId ?? 0,
      ));
      result.fold(
        (failure) => emit(ExpedicionScanError(failure.message)),
        (_) => emit(const ExpedicionScanUndone()),
      );
      return;
    }

    if (event.itemSuelto != null) {
      final item = event.itemSuelto!;
      final result = await deshacerItemSueltoUseCase(DeshacerItemSueltoParams(
        expeditionId: item.expeditionId ?? 0,
        packingId: item.packingId ?? 0,
      ));
      result.fold(
        (failure) => emit(ExpedicionScanError(failure.message)),
        (_) => emit(const ExpedicionScanUndone()),
      );
    }
  }
}
