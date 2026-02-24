import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'cluster_picking_event.dart';
part 'cluster_picking_state.dart';

class ClusterPickingBloc
    extends Bloc<ClusterPickingEvent, ClusterPickingState> {
  ClusterPickingBloc() : super(ClusterPickingInitial()) {
    on<ScanBarcodeEvent>(_onScanBarcode);
  }

  void _onScanBarcode(
    ScanBarcodeEvent event,
    Emitter<ClusterPickingState> emit,
  ) {
    //  try {
    //   print('scannedValue: ${event.scannedValue}');
    //   switch (event.scan) {
    //     case 'toDo':
    //       // Acumulador de valores escaneados
    //       scannedToDo += event.scannedValue.trim();
    //       print('scannedToDo: $scannedToDo.');
    //       emit(UpdateScannedValueState(scannedToDo, event.scan));
    //       break;
    //     default:
    //       print('Scan type not recognized: ${event.scan}');
    //   }
    // } catch (e, s) {
    //   print("❌ Error en _onUpdateScannedValueEvent: $e, $s");
    // }
  }
}
