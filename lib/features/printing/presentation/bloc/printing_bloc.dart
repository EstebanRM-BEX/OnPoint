import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/printer.dart';
import '../../domain/entities/printer_report.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import '../../domain/usecases/get_printers.dart';
import '../../domain/usecases/print_report.dart';

part 'printing_event.dart';
part 'printing_state.dart';

@injectable
class PrintingBloc extends Bloc<PrintingEvent, PrintingState> {
  final GetPrinters getPrinters;
  final PrintReport printReport;

  Printer? selectedPrinter;
  PrinterReport? selectedReport;

  List<Printer> printers = [];

  PrintingBloc({
    required this.getPrinters,
    required this.printReport,
  }) : super(PrintingInitial()) {
    on<LoadPrintersEvent>(_onLoadPrinters);
    on<SelectPrinterEvent>(_onSelectPrinter);
    on<SelectReportEvent>(_onSelectReport);
    on<ExecutePrintEvent>(_onExecutePrint);
  }

  Future<void> _onLoadPrinters(
    LoadPrintersEvent event,
    Emitter<PrintingState> emit,
  ) async {
    emit(PrintersLoading());
    final result = await getPrinters(NoParams());
    result.fold(
      (failure) => emit(PrintersError(failure.message)),
      (printers) {
        this.printers = printers;
        emit(PrintersLoaded(printers));
      },
    );
  }

  void _onSelectPrinter(
    SelectPrinterEvent event,
    Emitter<PrintingState> emit,
  ) {
    selectedPrinter = event.printer;
    selectedReport = null; // Reset report when printer changes
    if (state is PrintersLoaded) {
      emit(PrintersLoaded((state as PrintersLoaded).printers));
    }
  }

  void _onSelectReport(
    SelectReportEvent event,
    Emitter<PrintingState> emit,
  ) {
    selectedReport = event.report;
    if (state is PrintersLoaded) {
      emit(PrintersLoaded((state as PrintersLoaded).printers));
    }
  }

  Future<void> _onExecutePrint(
    ExecutePrintEvent event,
    Emitter<PrintingState> emit,
  ) async {
    if (selectedPrinter == null || selectedReport == null) {
      emit(const PrintError('Seleccione impresora y reporte'));
      return;
    }

    emit(PrintingInProgress());

    final userId = await PrefUtils.getUserId();

    final result = await printReport(PrintReportParams(
      printerId: selectedPrinter!.printerId,
      name: selectedReport!.name,
      reportName: selectedReport!.reportName,
      model: selectedReport!.model,
      resIds: event.resIds,
      companyId: event.companyId,
      userId: userId,
      copies: event.copies,
    ));

    result.fold(
      (failure) => emit(PrintError(failure.message)),
      (success) => emit(PrintSuccess('Impresión enviada con éxito', printers)),
    );
  }
}
