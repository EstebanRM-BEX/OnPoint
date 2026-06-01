import 'package:wms_app/features/picking/domain/entities/pick.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';

/// Data model for Pick entity.
/// Extends the domain entity and adds mapping from the legacy [ResultPick] model.
class PickModel extends Pick {
  const PickModel({
    super.id,
    super.name,
    super.observacion,
    super.fechaCreacion,
    super.proveedor,
    super.origin,
    super.priority,
    super.responsableId,
    super.responsable,
    super.pickingType,
    super.startTimeTransfer,
    super.backorderId,
    super.backorderName,
    super.isSeparate,
    super.isSelected,
    super.zonaEntrega,
    super.numeroLineas,
    super.numeroItems,
  });

  /// Creates a [PickModel] from a [ResultPick] legacy model.
  factory PickModel.fromResultPick(ResultPick r) {
    return PickModel(
      id: r.id,
      name: r.name,
      observacion: r.observacion,
      fechaCreacion: r.fechaCreacion,
      proveedor: r.proveedor,
      origin: r.origin,
      priority: r.priority,
      responsableId: r.responsableId,
      responsable: r.responsable,
      pickingType: r.pickingType,
      startTimeTransfer: r.startTimeTransfer,
      backorderId: r.backorderId,
      backorderName: r.backorderName,
      isSeparate: r.isSeparate,
      isSelected: r.isSelected,
      zonaEntrega: r.zonaEntrega,
      numeroLineas: r.numeroLineas,
      numeroItems: r.numeroItems,
    );
  }
}
