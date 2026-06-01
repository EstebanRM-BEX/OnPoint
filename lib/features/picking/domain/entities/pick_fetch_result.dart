import 'package:wms_app/features/picking/domain/entities/pick.dart';

/// Result of a fetch picks operation.
/// Combines the list of picks and a flag indicating if an app update is needed.
class PickFetchResult {
  final List<Pick> picks;
  final bool needsUpdate;

  const PickFetchResult({
    required this.picks,
    required this.needsUpdate,
  });
}
