import 'package:equatable/equatable.dart';

class PrinterReport extends Equatable {
  final int id;
  final String name;
  final String reportName;
  final String reportType;
  final String model;

  const PrinterReport({
    required this.id,
    required this.name,
    required this.reportName,
    required this.reportType,
    required this.model,
  });

  @override
  List<Object?> get props => [id, name, reportName, reportType, model];
}
