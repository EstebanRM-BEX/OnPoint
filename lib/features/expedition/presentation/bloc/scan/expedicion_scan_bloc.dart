import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'expedicion_scan_event.dart';
part 'expedicion_scan_state.dart';

/// Bloc de scan_product_screen. Por ahora la validación es solo visual (sin
/// llamada a backend ni persistencia) — únicamente confirma la acción en UI.
@injectable
class ExpedicionScanBloc extends Bloc<ExpedicionScanEvent, ExpedicionScanState> {
  ExpedicionScanBloc() : super(const ExpedicionScanInitial()) {
    on<ValidarExpedicionScanEvent>((event, emit) {
      emit(const ExpedicionScanValidated());
    });
  }
}
