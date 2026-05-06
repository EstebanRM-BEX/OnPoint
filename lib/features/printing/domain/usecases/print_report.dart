import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/printing_repository.dart';

@lazySingleton
class PrintReport implements UseCase<bool, PrintReportParams> {
  final PrintingRepository repository;

  PrintReport(this.repository);

  @override
  Future<Either<Failure, bool>> call(PrintReportParams params) async {
    final result = await repository.printReport(
      printerId: params.printerId,
      name: params.name,
      reportName: params.reportName,
      model: params.model,
      resId: params.resId,
      companyId: params.companyId,
      copies: params.copies,
    );
    return result.fold(
      (error) => Left(ServerFailure(error.message)),
      (success) => Right(success),
    );
  }
}

class PrintReportParams extends Equatable {
  final int printerId;
  final String name;
  final String reportName;
  final String model;
  final int resId;
  final int companyId;
  final int copies;

  const PrintReportParams({
    required this.printerId,
    required this.name,
    required this.reportName,
    required this.model,
    required this.resId,
    required this.companyId,
    this.copies = 1,
  });

  @override
  List<Object?> get props =>
      [printerId, name, reportName, model, resId, companyId, copies];
}
