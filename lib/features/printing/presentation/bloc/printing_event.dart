part of 'printing_bloc.dart';

abstract class PrintingEvent extends Equatable {
  const PrintingEvent();

  @override
  List<Object?> get props => [];
}

class LoadPrintersEvent extends PrintingEvent {}

class SelectPrinterEvent extends PrintingEvent {
  final Printer? printer;
  const SelectPrinterEvent(this.printer);

  @override
  List<Object?> get props => [printer];
}

class SelectReportEvent extends PrintingEvent {
  final PrinterReport? report;
  const SelectReportEvent(this.report);

  @override
  List<Object?> get props => [report];
}

class ExecutePrintEvent extends PrintingEvent {
  final List<int> resIds;
  final int companyId;
  final int copies;
  const ExecutePrintEvent(
      {required this.resIds, required this.companyId, this.copies = 1});

  @override
  List<Object?> get props => [resIds, companyId, copies];
}
