import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/picking/domain/entities/pick.dart';
import 'package:wms_app/features/picking/domain/entities/pick_fetch_result.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/PickhWithProducts_model.dart';

/// Repository interface for the picking feature.
/// This is an abstraction that will be implemented in the data layer.
abstract class PickingRepository {
  /// Fetches active picks from the remote source and persists them locally.
  Future<Either<Failure, PickFetchResult>> fetchPicks();

  /// Fetches picks history filtered by date.
  Future<Either<Failure, List<Pick>>> fetchPicksHistory(String date);

  /// Assigns the current user to a pick.
  Future<Either<Failure, Unit>> assignUserToPick(int pickId);

  /// Records start or end time for a pick.
  Future<Either<Failure, Unit>> recordPickTime(int pickId, String timeType);

  /// Retrieves a pick with its associated product lines from local storage.
  Future<Either<Failure, PickWithProducts>> getPickWithProducts(int pickId);

  /// Retrieves user configurations from local storage.
  Future<Either<Failure, UserConfigurationModel>> getPickConfigurations();
}
