import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../entities/packaging_type.dart';
import '../repositories/packaging_type_repository.dart';

@lazySingleton
class GetLocalPackagingTypesUseCase {
  final PackagingTypeRepository repository;

  GetLocalPackagingTypesUseCase(this.repository);

  Future<Either<Exception, List<PackagingType>>> call() {
    return repository.getLocalPackagingTypes();
  }
}
