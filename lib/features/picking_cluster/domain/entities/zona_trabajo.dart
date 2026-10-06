import 'package:equatable/equatable.dart';

/// Zona de trabajo asignada a un batch de Pick Cluster
/// (`zonas_trabajo` de /api/cluster/picking_batchs).
class ZonaTrabajo extends Equatable {
  final int? id;
  final String? name;
  final int? batchId;
  final int? zoneId;
  final String? estado;
  final int? userId;
  final String? userName;

  const ZonaTrabajo({
    this.id,
    this.name,
    this.batchId,
    this.zoneId,
    this.estado,
    this.userId,
    this.userName,
  });

  @override
  List<Object?> get props => [id, name, batchId, zoneId, estado, userId, userName];
}
