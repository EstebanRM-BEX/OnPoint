import '../../domain/entities/printer.dart';
import 'printer_report_model.dart';

class PrinterModel extends Printer {
  const PrinterModel({
    required super.printerId,
    required super.printerName,
    required super.printerType,
    required super.hostmachine,
    required List<PrinterReportModel> super.availableReports,
  });

  factory PrinterModel.fromJson(Map<String, dynamic> json) {
    return PrinterModel(
      printerId: json['printer_id'] as int,
      printerName: json['printer_name'] as String,
      printerType: json['printer_type'] as String,
      hostmachine: json['hostmachine'] as String,
      availableReports: (json['available_reports'] as List<dynamic>?)
              ?.map(
                  (e) => PrinterReportModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'printer_id': printerId,
      'printer_name': printerName,
      'printer_type': printerType,
      'hostmachine': hostmachine,
      'available_reports': (availableReports as List<PrinterReportModel>)
          .map((e) => e.toJson())
          .toList(),
    };
  }
}
