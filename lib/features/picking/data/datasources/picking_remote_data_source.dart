import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/data/picking_pick_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

/// Abstract interface for picking remote data operations.
abstract class PickingRemoteDataSource {
  /// Fetches active picks from the remote server.
  Future<ResponsePickResult> fetchPicks();

  /// Fetches picks history for the given date.
  Future<List<ResultPick>> fetchPicksHistory(String date);
}

/// Implementation of [PickingRemoteDataSource] using [PickingPickRepository].
@LazySingleton(as: PickingRemoteDataSource)
class PickingRemoteDataSourceImpl implements PickingRemoteDataSource {
  final PickingPickRepository pickingRepository = PickingPickRepository();

  @override
  Future<ResponsePickResult> fetchPicks() async {
    return await pickingRepository.resPicks(false);
  }

  @override
  Future<List<ResultPick>> fetchPicksHistory(String date) async {
    return await pickingRepository.resPicksDone(false, date);
  }
}
