import '../../domain/entities/printer_report.dart';

class PrinterReportModel extends PrinterReport {
  const PrinterReportModel({
    required int id,
    required String name,
    required String reportName,
    required String reportType,
    required String model,
  }) : super(
          id: id,
          name: name,
          reportName: reportName,
          reportType: reportType,
          model: model,
        );

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
