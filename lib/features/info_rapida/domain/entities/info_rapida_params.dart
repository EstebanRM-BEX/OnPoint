import 'package:equatable/equatable.dart';

/// Parámetros para actualizar información de un producto desde Información Rápida.
class ActualizarProductoParams extends Equatable {
  final int productId;
  final String name;
  final String barcode;
  final String defaultCode;
  final String listPrice;
  final String weight;
  final String volume;

  const ActualizarProductoParams({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.defaultCode,
    required this.listPrice,
    required this.weight,
    required this.volume,
  });

  @override
  List<Object?> get props => [
        productId,
        name,
        barcode,
        defaultCode,
        listPrice,
        weight,
        volume,
      ];
}

/// Parámetros para actualizar información de una ubicación desde Información Rápida.
class ActualizarUbicacionParams extends Equatable {
  final int locationId;
  final String name;
  final String barcode;

  const ActualizarUbicacionParams({
    required this.locationId,
    required this.name,
    required this.barcode,
  });

  @override
  List<Object?> get props => [locationId, name, barcode];
}

/// Parámetros para crear una transferencia individual de un producto.
class CrearTransferenciaIndividualParams extends Equatable {
  final int idAlmacen;
  final int idMove;
  final int idProducto;
  final int idLote;
  final int idUbicacionOrigen;
  final int? idUbicacionDestino;
  final double cantidadEnviada;
  final int? idOperario;
  final int? timeLine;
  final String? fechaTransaccion;
  final String observacion;
  final int? idPropietario;
  final String? dateStart;
  final String? dateEnd;

  const CrearTransferenciaIndividualParams({
    required this.idAlmacen,
    required this.idMove,
    required this.idProducto,
    required this.idLote,
    required this.idUbicacionOrigen,
    this.idUbicacionDestino,
    required this.cantidadEnviada,
    this.idOperario,
    this.timeLine,
    this.fechaTransaccion,
    required this.observacion,
    this.idPropietario,
    this.dateStart,
    this.dateEnd,
  });

  @override
  List<Object?> get props => [
        idAlmacen,
        idMove,
        idProducto,
        idLote,
        idUbicacionOrigen,
        idUbicacionDestino,
        cantidadEnviada,
        idOperario,
        timeLine,
        fechaTransaccion,
        observacion,
        idPropietario,
        dateStart,
        dateEnd,
      ];
}

/// Parámetros de cada producto dentro de una transferencia masiva.
class ItemTransferenciaParams extends Equatable {
  final int idProducto;
  final double cantidadEnviada;
  final int idLote;
  final int timeLine;
  final int idPropietario;
  final double quantitySegundaUnidad;

  const ItemTransferenciaParams({
    required this.idProducto,
    required this.cantidadEnviada,
    required this.idLote,
    required this.timeLine,
    required this.idPropietario,
    this.quantitySegundaUnidad = 0.0,
  });

  @override
  List<Object?> get props => [
        idProducto,
        cantidadEnviada,
        idLote,
        timeLine,
        idPropietario,
        quantitySegundaUnidad,
      ];
}

/// Parámetros para crear una transferencia masiva con múltiples productos.
class CrearTransferenciaMasivaParams extends Equatable {
  final String dateStart;
  final String dateEnd;
  final int idAlmacen;
  final int idUbicacionOrigen;
  final int idUbicacionDestino;
  final int idOperario;
  final String fechaTransaccion;
  final List<ItemTransferenciaParams> listItems;

  const CrearTransferenciaMasivaParams({
    required this.dateStart,
    required this.dateEnd,
    required this.idAlmacen,
    required this.idUbicacionOrigen,
    required this.idUbicacionDestino,
    required this.idOperario,
    required this.fechaTransaccion,
    required this.listItems,
  });

  @override
  List<Object?> get props => [
        dateStart,
        dateEnd,
        idAlmacen,
        idUbicacionOrigen,
        idUbicacionDestino,
        idOperario,
        fechaTransaccion,
        listItems,
      ];
}
