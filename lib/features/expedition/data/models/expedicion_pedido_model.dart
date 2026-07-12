import 'package:wms_app/features/expedition/data/models/expedicion_json_utils.dart';
import 'package:wms_app/features/expedition/data/models/item_suelto_expedicion_model.dart';
import 'package:wms_app/features/expedition/data/models/paquete_expedicion_model.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';
import 'package:wms_app/src/presentation/providers/db/expedition/tbl_expedicion_pedidos/expedicion_pedidos_table.dart';

class ExpedicionPedidoModel extends ExpedicionPedido {
  const ExpedicionPedidoModel({
    super.expeditionId,
    super.nombre,
    super.fecha,
    super.cliente,
    super.documentoOrigen,
    super.numeroLineas,
    super.totalCantidades,
    super.numeroPaquetes,
    super.productoSueltos,
    super.totalPeso,
    super.observacion,
    super.manejoPropietario,
    super.propietario,
    super.estado,
    super.warehouseId,
    super.warehouseName,
    super.responsableId,
    super.responsable,
    super.pickingType,
    super.startTimeTransfer,
    super.endTimeTransfer,
    super.zonaEntrega,
    super.itemsPackValidados = const [],
    super.itemsPackPendientes = const [],
    super.itemsValidados = const [],
    super.itemsPendientes = const [],
  });

  factory ExpedicionPedidoModel.fromJson(Map<String, dynamic> json) {
    final validados = json['items_pack_validados'] == null
        ? <PaqueteExpedicion>[]
        : List<PaqueteExpedicion>.from((json['items_pack_validados'] as List)
            .map((x) =>
                PaqueteExpedicionModel.fromJson(x as Map<String, dynamic>)));

    final pendientes = json['items_pack_pendientes'] == null
        ? <PaqueteExpedicion>[]
        : List<PaqueteExpedicion>.from((json['items_pack_pendientes'] as List)
            .map((x) =>
                PaqueteExpedicionModel.fromJson(x as Map<String, dynamic>)));

    final itemsSueltosValidados = json['items_validados'] == null
        ? <ItemSueltoExpedicion>[]
        : List<ItemSueltoExpedicion>.from((json['items_validados'] as List)
            .map((x) => ItemSueltoExpedicionModel.fromJson(
                x as Map<String, dynamic>,
                origen: 'validado')));

    final itemsSueltosPendientes = json['items_pendientes'] == null
        ? <ItemSueltoExpedicion>[]
        : List<ItemSueltoExpedicion>.from((json['items_pendientes'] as List)
            .map((x) => ItemSueltoExpedicionModel.fromJson(
                x as Map<String, dynamic>,
                origen: 'pendiente')));

    return ExpedicionPedidoModel(
      expeditionId: dynamicToInt(json['expedition_id']),
      nombre: dynamicToString(json['nombre']),
      fecha: json['fecha'] == null || json['fecha'] is bool
          ? null
          : DateTime.tryParse(json['fecha'].toString()),
      cliente: dynamicToString(json['cliente']),
      documentoOrigen: dynamicToString(json['documento_origen']),
      numeroLineas: dynamicToInt(json['numero_lineas']),
      totalCantidades: dynamicToInt(json['total_cantidades']),
      numeroPaquetes: dynamicToInt(json['numero_paquetes']),
      productoSueltos: dynamicToInt(json['producto_sueltos']),
      totalPeso: dynamicToDouble(json['total_peso']),
      observacion: dynamicToString(json['observacion']),
      manejoPropietario: dynamicToBool(json['manejo_propietario']),
      propietario: dynamicToString(json['propietario']),
      estado: dynamicToString(json['estado']),
      warehouseId: dynamicToInt(json['warehouse_id']),
      warehouseName: dynamicToString(json['warehouse_name']),
      responsableId: dynamicToInt(json['responsable_id']),
      responsable: dynamicToString(json['responsable']),
      pickingType: dynamicToString(json['picking_type']),
      startTimeTransfer: dynamicToString(json['start_time_transfer']),
      endTimeTransfer: dynamicToString(json['end_time_transfer']),
      zonaEntrega: dynamicToString(json['zona_entrega']),
      itemsPackValidados: validados,
      itemsPackPendientes: pendientes,
      itemsValidados: itemsSueltosValidados,
      itemsPendientes: itemsSueltosPendientes,
    );
  }

  factory ExpedicionPedidoModel.fromMap(Map<String, dynamic> map) {
    return ExpedicionPedidoModel(
      expeditionId: map[ExpedicionPedidosTable.columnExpeditionId] as int?,
      nombre: map[ExpedicionPedidosTable.columnNombre] as String?,
      fecha: map[ExpedicionPedidosTable.columnFecha] == null
          ? null
          : DateTime.tryParse(
              map[ExpedicionPedidosTable.columnFecha] as String),
      cliente: map[ExpedicionPedidosTable.columnCliente] as String?,
      documentoOrigen:
          map[ExpedicionPedidosTable.columnDocumentoOrigen] as String?,
      numeroLineas: map[ExpedicionPedidosTable.columnNumeroLineas] as int?,
      totalCantidades:
          map[ExpedicionPedidosTable.columnTotalCantidades] as int?,
      numeroPaquetes: map[ExpedicionPedidosTable.columnNumeroPaquetes] as int?,
      productoSueltos:
          map[ExpedicionPedidosTable.columnProductoSueltos] as int?,
      totalPeso: (map[ExpedicionPedidosTable.columnTotalPeso] as num?)
          ?.toDouble(),
      observacion: map[ExpedicionPedidosTable.columnObservacion] as String?,
      manejoPropietario:
          (map[ExpedicionPedidosTable.columnManejoPropietario] as int?) == 1,
      propietario: map[ExpedicionPedidosTable.columnPropietario] as String?,
      estado: map[ExpedicionPedidosTable.columnEstado] as String?,
      warehouseId: map[ExpedicionPedidosTable.columnWarehouseId] as int?,
      warehouseName: map[ExpedicionPedidosTable.columnWarehouseName] as String?,
      responsableId: map[ExpedicionPedidosTable.columnResponsableId] as int?,
      responsable: map[ExpedicionPedidosTable.columnResponsable] as String?,
      pickingType: map[ExpedicionPedidosTable.columnPickingType] as String?,
      startTimeTransfer:
          map[ExpedicionPedidosTable.columnStartTimeTransfer] as String?,
      endTimeTransfer:
          map[ExpedicionPedidosTable.columnEndTimeTransfer] as String?,
      zonaEntrega: map[ExpedicionPedidosTable.columnZonaEntrega] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      ExpedicionPedidosTable.columnExpeditionId: expeditionId,
      ExpedicionPedidosTable.columnNombre: nombre,
      ExpedicionPedidosTable.columnFecha: fecha?.toIso8601String(),
      ExpedicionPedidosTable.columnCliente: cliente,
      ExpedicionPedidosTable.columnDocumentoOrigen: documentoOrigen,
      ExpedicionPedidosTable.columnNumeroLineas: numeroLineas,
      ExpedicionPedidosTable.columnTotalCantidades: totalCantidades,
      ExpedicionPedidosTable.columnNumeroPaquetes: numeroPaquetes,
      ExpedicionPedidosTable.columnProductoSueltos: productoSueltos,
      ExpedicionPedidosTable.columnTotalPeso: totalPeso,
      ExpedicionPedidosTable.columnObservacion: observacion,
      ExpedicionPedidosTable.columnManejoPropietario:
          manejoPropietario == true ? 1 : 0,
      ExpedicionPedidosTable.columnPropietario: propietario,
      ExpedicionPedidosTable.columnEstado: estado,
      ExpedicionPedidosTable.columnWarehouseId: warehouseId,
      ExpedicionPedidosTable.columnWarehouseName: warehouseName,
      ExpedicionPedidosTable.columnResponsableId: responsableId,
      ExpedicionPedidosTable.columnResponsable: responsable,
      ExpedicionPedidosTable.columnPickingType: pickingType,
      ExpedicionPedidosTable.columnStartTimeTransfer: startTimeTransfer,
      ExpedicionPedidosTable.columnEndTimeTransfer: endTimeTransfer,
      ExpedicionPedidosTable.columnZonaEntrega: zonaEntrega,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}
