import '../../domain/entities/printer_report.dart';

class PrinterReportModel extends PrinterReport {
  const PrinterReportModel({
    required super.id,
    required super.name,
    required super.reportName,
    required super.reportType,
    required super.model,
  });

  factory PrinterReportModel.fromJson(Map<String, dynamic> json) {
    return PrinterReportModel(
      id: json['id'] as int,
      name: json['name'] as String,
      reportName: json['report_name'] as String,
      reportType: json['report_type'] as String,
      model: json['model'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'report_name': reportName,
      'report_type': reportType,
      'model': model,
    };
  }
}
