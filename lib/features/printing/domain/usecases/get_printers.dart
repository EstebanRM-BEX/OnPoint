import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/printer.dart';
import '../repositories/printing_repository.dart';

@lazySingleton
class GetPrinters implements UseCase<List<Printer>, NoParams> {
  final PrintingRepository repository;

  GetPrinters(this.repository);

  @override
  Future<Either<Failure, List<Printer>>> call(NoParams params) async {
    return await repository.getPrinters();
  }
}
