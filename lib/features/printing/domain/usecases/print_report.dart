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
      resIds: params.resIds,
      companyId: params.companyId,
      userId: params.userId,
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
  final List<int> resIds;
  final int companyId;
  final int userId;
  final int copies;

  const PrintReportParams({
    required this.printerId,
    required this.name,
    required this.reportName,
    required this.model,
    required this.resIds,
    required this.companyId,
    required this.userId,
    this.copies = 1,
  });

  @override
  List<Object?> get props =>
      [printerId, name, reportName, model, resIds, companyId, userId, copies];
}
