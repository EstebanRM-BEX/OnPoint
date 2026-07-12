part of 'expedicion_scan_bloc.dart';

sealed class ExpedicionScanState extends Equatable {
  const ExpedicionScanState();

  @override
  List<Object> get props => [];
}

final class ExpedicionScanInitial extends ExpedicionScanState {
  const ExpedicionScanInitial();
}

final class ExpedicionScanValidated extends ExpedicionScanState {
  const ExpedicionScanValidated();
}
