import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/printer.dart';

abstract class PrintingRepository {
  Future<Either<Failure, List<Printer>>> getPrinters();

  Future<Either<Failure, bool>> printReport({
    required int printerId,
    required String name,
    required String reportName,
    required String model,
    required int resId,
    required int companyId,
    int copies = 1,
  });
}
