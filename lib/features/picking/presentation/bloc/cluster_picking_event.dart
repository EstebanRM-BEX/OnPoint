part of 'cluster_picking_bloc.dart';

sealed class ClusterPickingEvent extends Equatable {
  const ClusterPickingEvent();

  @override
  List<Object> get props => [];
}

class ScanBarcodeEvent extends ClusterPickingEvent {
  final String barcode;
  const ScanBarcodeEvent(this.barcode);

  @override
  List<Object> get props => [barcode];
}
