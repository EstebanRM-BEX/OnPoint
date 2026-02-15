import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/enterprise_info.dart';
import '../entities/recent_url.dart';

abstract class EnterpriseRepository {
  /// Fetches available databases for a given [url].
  Future<Either<Failure, EnterpriseInfo>> searchEnterprise(String url);

  /// Retrieves the history of recently used URLs.
  Future<Either<Failure, List<RecentUrl>>> getRecentUrls();

  /// Saves a [url] to the recent history.
  Future<Either<Failure, void>> saveRecentUrl(RecentUrl recentUrl);

  /// Deletes a [url] from the recent history.
  Future<Either<Failure, void>> deleteRecentUrl(String url);
}
