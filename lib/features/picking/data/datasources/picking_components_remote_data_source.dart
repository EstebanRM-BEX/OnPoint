import 'package:injectable/injectable.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/data/picking_pick_repository.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

/// Abstract interface for components remote data operations.
abstract class PickingComponentsRemoteDataSource {
  /// Fetches active component picks from the server.
  Future<ResponsePickResult> fetchComponents();

  /// Fetches component picks history for the given date.
  Future<List<ResultPick>> fetchComponentsHistory(String date);
}

/// Implementation using [PickingPickRepository].
@LazySingleton(as: PickingComponentsRemoteDataSource)
class PickingComponentsRemoteDataSourceImpl
    implements PickingComponentsRemoteDataSource {
  final PickingPickRepository pickingRepository = PickingPickRepository();

  @override
  Future<ResponsePickResult> fetchComponents() async {
    return await pickingRepository.resPickingComponentes(false);
  }

  @override
  Future<List<ResultPick>> fetchComponentsHistory(String date) async {
    return await pickingRepository.resPicksComponentsDone(false, date);
  }
}
