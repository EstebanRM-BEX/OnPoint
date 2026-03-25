import 'package:equatable/equatable.dart';
import 'printer_report.dart';

class Printer extends Equatable {
  final int printerId;
  final String printerName;
  final String printerType;
  final String hostmachine;
  final List<PrinterReport> availableReports;

  const Printer({
    required this.printerId,
    required this.printerName,
    required this.printerType,
    required this.hostmachine,
    required this.availableReports,
  });

  @override
  List<Object?> get props => [
        printerId,
        printerName,
        printerType,
        hostmachine,
        availableReports,
      ];
}
