import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/packaging_type.dart';
import '../../domain/repositories/packaging_type_repository.dart';
import '../datasources/local/packaging_type_local_datasource.dart';
import '../datasources/remote/packaging_type_remote_datasource.dart';

@LazySingleton(as: PackagingTypeRepository)
class PackagingTypeRepositoryImpl implements PackagingTypeRepository {
  final PackagingTypeRemoteDataSource remoteDataSource;
  final PackagingTypeLocalDataSource localDataSource;

  PackagingTypeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Exception, List<PackagingType>>> syncPackagingTypes() async {
    try {
      // Fetch from remote
      final remoteData = await remoteDataSource.getPackagingTypes();
      
      // Save to local
      await localDataSource.savePackagingTypes(remoteData);
      
      // Return local data to ensure consistency
      final localData = await localDataSource.getPackagingTypes();
      return Right(localData);
    } on Exception catch (_) {
      // If remote fails, fallback to local data
      try {
        final localData = await localDataSource.getPackagingTypes();
        return Right(localData);
      } on Exception catch (localException) {
        return Left(localException);
      }
    }
  }

  @override
  Future<Either<Exception, List<PackagingType>>> getLocalPackagingTypes() async {
    try {
      final localData = await localDataSource.getPackagingTypes();
      return Right(localData);
    } on Exception catch (e) {
      return Left(e);
    } catch (_) {
      return Left(Exception('Unknown error occurred'));
    }
  }
}
