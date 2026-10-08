import 'package:equatable/equatable.dart';

/// Resultado de una transferencia individual creada desde Información Rápida.
class TransferenciaIndividualResult extends Equatable {
  final int? transferenciaId;
  final String? nombreTransferencia;
  final int? lineaId;
  final double? cantidadEnviada;
  final int? idProducto;
  final String? nombreProducto;
  final String? ubicacionOrigen;
  final String? ubicacionDestino;
  final String? fechaTransaccion;
  final String? observacion;

  const TransferenciaIndividualResult({
    this.transferenciaId,
    this.nombreTransferencia,
    this.lineaId,
    this.cantidadEnviada,
    this.idProducto,
    this.nombreProducto,
    this.ubicacionOrigen,
    this.ubicacionDestino,
    this.fechaTransaccion,
    this.observacion,
  });

  @override
  List<Object?> get props => [
        transferenciaId,
        nombreTransferencia,
        lineaId,
        cantidadEnviada,
        idProducto,
        nombreProducto,
        ubicacionOrigen,
        ubicacionDestino,
        fechaTransaccion,
        observacion,
      ];
}

/// Resultado de una transferencia masiva creada desde Información Rápida.
class TransferenciaMasivaResult extends Equatable {
  final int? transferenciaId;
  final String? nombreTransferencia;
  final int? totalItems;
  final int? ubicacionOrigenId;
  final int? ubicacionDestinoId;
  final List<ItemTransferido> itemsProcesados;

  const TransferenciaMasivaResult({
    this.transferenciaId,
    this.nombreTransferencia,
    this.totalItems,
    this.ubicacionOrigenId,
    this.ubicacionDestinoId,
    this.itemsProcesados = const [],
  });

  @override
  List<Object?> get props => [
        transferenciaId,
        nombreTransferencia,
        totalItems,
        ubicacionOrigenId,
        ubicacionDestinoId,
        itemsProcesados,
      ];
}

/// Detalle de una línea de producto procesada en una transferencia masiva.
class ItemTransferido extends Equatable {
  final int? lineaId;
  final int? productoId;
  final String? productoNombre;
  final double? cantidad;
  final int? loteId;
  final String? observacion;

  const ItemTransferido({
    this.lineaId,
    this.productoId,
    this.productoNombre,
    this.cantidad,
    this.loteId,
    this.observacion,
  });

  @override
  List<Object?> get props => [
        lineaId,
        productoId,
        productoNombre,
        cantidad,
        loteId,
        observacion,
      ];
}
