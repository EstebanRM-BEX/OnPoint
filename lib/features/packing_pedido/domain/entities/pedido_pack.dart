import 'package:equatable/equatable.dart';

/// Pedido (transferencia) listo para empacar.
class PedidoPack extends Equatable {
  final int id;
  final int? batchId;
  final String name;
  final String referencia;
  final String contactoName;
  final String observacion;
  final DateTime? fechaCreacion;

  /// `cluster` → empaque con peso y tipo de empaque (send_cluster/pack);
  /// cualquier otro valor → send_transfer/pack.
  final String configPacking;

  /// '1' = alta, '0' = normal (tal cual lo manda Odoo).
  final String priority;
  final String state;
  final String pickingType;

  final int? locationId;
  final String locationName;
  final String locationBarcode;
  final int? locationDestId;
  final String locationDestName;
  final String locationDestBarcode;
  final String warehouseName;

  final int? responsableId;
  final String responsable;

  final int? backorderId;
  final String backorderName;
  final String createBackorder;

  final int numeroLineas;
  final double numeroItems;
  final int numeroPaquetes;

  final String orderTms;
  final String zonaEntrega;
  final String zonaEntregaTms;

  final String startTimeTransfer;
  final String endTimeTransfer;

  final bool isSelected;
  final bool isStarted;
  final bool isTerminate;

  const PedidoPack({
    required this.id,
    this.batchId,
    this.name = '',
    this.referencia = '',
    this.contactoName = '',
    this.observacion = '',
    this.fechaCreacion,
    this.configPacking = '',
    this.priority = '0',
    this.state = '',
    this.pickingType = '',
    this.locationId,
    this.locationName = '',
    this.locationBarcode = '',
    this.locationDestId,
    this.locationDestName = '',
    this.locationDestBarcode = '',
    this.warehouseName = '',
    this.responsableId,
    this.responsable = '',
    this.backorderId,
    this.backorderName = '',
    this.createBackorder = '',
    this.numeroLineas = 0,
    this.numeroItems = 0,
    this.numeroPaquetes = 0,
    this.orderTms = '',
    this.zonaEntrega = '',
    this.zonaEntregaTms = '',
    this.startTimeTransfer = '',
    this.endTimeTransfer = '',
    this.isSelected = false,
    this.isStarted = false,
    this.isTerminate = false,
  });

  bool get esCluster => configPacking == 'cluster';
  bool get esPrioritario => priority == '1';
  bool get tieneBackorder => backorderName.isNotEmpty;
  bool get tieneResponsable => responsableId != null && responsableId != 0;

  PedidoPack copyWith({
    int? responsableId,
    String? responsable,
    String? startTimeTransfer,
    String? endTimeTransfer,
    bool? isSelected,
    bool? isStarted,
    bool? isTerminate,
  }) {
    return PedidoPack(
      id: id,
      batchId: batchId,
      name: name,
      referencia: referencia,
      contactoName: contactoName,
      observacion: observacion,
      fechaCreacion: fechaCreacion,
      configPacking: configPacking,
      priority: priority,
      state: state,
      pickingType: pickingType,
      locationId: locationId,
      locationName: locationName,
      locationBarcode: locationBarcode,
      locationDestId: locationDestId,
      locationDestName: locationDestName,
      locationDestBarcode: locationDestBarcode,
      warehouseName: warehouseName,
      responsableId: responsableId ?? this.responsableId,
      responsable: responsable ?? this.responsable,
      backorderId: backorderId,
      backorderName: backorderName,
      createBackorder: createBackorder,
      numeroLineas: numeroLineas,
      numeroItems: numeroItems,
      numeroPaquetes: numeroPaquetes,
      orderTms: orderTms,
      zonaEntrega: zonaEntrega,
      zonaEntregaTms: zonaEntregaTms,
      startTimeTransfer: startTimeTransfer ?? this.startTimeTransfer,
      endTimeTransfer: endTimeTransfer ?? this.endTimeTransfer,
      isSelected: isSelected ?? this.isSelected,
      isStarted: isStarted ?? this.isStarted,
      isTerminate: isTerminate ?? this.isTerminate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    responsableId,
    startTimeTransfer,
    endTimeTransfer,
    isSelected,
    isStarted,
    isTerminate,
    numeroPaquetes,
  ];
}
