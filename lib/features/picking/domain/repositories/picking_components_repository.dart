import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/picking/domain/entities/pick.dart';
import 'package:wms_app/features/picking/domain/entities/pick_fetch_result.dart';

/// Repository interface for the picking-components feature.
abstract class PickingComponentsRepository {
  /// Fetches active component picks from remote and persists locally.
  Future<Either<Failure, PickFetchResult>> fetchComponents();

  /// Reads component picks from local SQLite.
  Future<Either<Failure, List<Pick>>> fetchComponentsFromDb();

  /// Fetches component picks history filtered by date.
  Future<Either<Failure, List<Pick>>> fetchComponentsHistory(String date);
}
