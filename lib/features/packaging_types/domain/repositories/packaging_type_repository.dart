import 'package:fpdart/fpdart.dart';
import '../entities/packaging_type.dart';

abstract class PackagingTypeRepository {
  /// Fetches packaging types from the remote API, saves them locally, and returns the list.
  Future<Either<Exception, List<PackagingType>>> syncPackagingTypes();

  /// Retrieves the list of packaging types from the local database.
  Future<Either<Exception, List<PackagingType>>> getLocalPackagingTypes();
}
