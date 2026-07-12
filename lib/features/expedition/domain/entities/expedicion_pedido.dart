import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';

class ExpedicionPedido {
  final int? expeditionId;
  final String? nombre;
  final DateTime? fecha;
  final String? cliente;
  final String? documentoOrigen;
  final int? numeroLineas;
  final int? totalCantidades;
  final int? numeroPaquetes;
  final int? productoSueltos;
  final double? totalPeso;
  final String? observacion;
  final bool? manejoPropietario;
  final String? propietario;
  final String? estado;
  final int? warehouseId;
  final String? warehouseName;
  final int? responsableId;
  final String? responsable;
  final String? pickingType;
  final String? startTimeTransfer;
  final String? endTimeTransfer;
  final String? zonaEntrega;
  final List<PaqueteExpedicion> itemsPackValidados;
  final List<PaqueteExpedicion> itemsPackPendientes;
  final List<ItemSueltoExpedicion> itemsValidados;
  final List<ItemSueltoExpedicion> itemsPendientes;

  const ExpedicionPedido({
    this.expeditionId,
    this.nombre,
    this.fecha,
    this.cliente,
    this.documentoOrigen,
    this.numeroLineas,
    this.totalCantidades,
    this.numeroPaquetes,
    this.productoSueltos,
    this.totalPeso,
    this.observacion,
    this.manejoPropietario,
    this.propietario,
    this.estado,
    this.warehouseId,
    this.warehouseName,
    this.responsableId,
    this.responsable,
    this.pickingType,
    this.startTimeTransfer,
    this.endTimeTransfer,
    this.zonaEntrega,
    this.itemsPackValidados = const [],
    this.itemsPackPendientes = const [],
    this.itemsValidados = const [],
    this.itemsPendientes = const [],
  });
}
