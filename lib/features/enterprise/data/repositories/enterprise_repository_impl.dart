import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/enterprise_info.dart';
import '../../domain/entities/recent_url.dart';
import '../../domain/repositories/enterprise_repository.dart';
import '../datasources/enterprise_local_data_source.dart';
import '../datasources/enterprise_remote_data_source.dart';
import '../models/recent_url_model.dart';

@LazySingleton(as: EnterpriseRepository)
class EnterpriseRepositoryImpl implements EnterpriseRepository {
  final EnterpriseRemoteDataSource remoteDataSource;
  final EnterpriseLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  EnterpriseRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, EnterpriseInfo>> searchEnterprise(String url) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final enterpriseInfo = await remoteDataSource.searchEnterprise(url);
      // If search is successful, we cache the URL in both history and current preferences
      await localDataSource.cacheEnterpriseUrl(url);
      await localDataSource.saveRecentUrl(RecentUrlModel(
        url: url,
        fecha: DateTime.now(),
      ));
      return Right(enterpriseInfo);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecentUrl>>> getRecentUrls() async {
    try {
      final models = await localDataSource.getRecentUrls();
      return Right(models);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecentUrl(String url) async {
    try {
      await localDataSource.deleteRecentUrl(url);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
