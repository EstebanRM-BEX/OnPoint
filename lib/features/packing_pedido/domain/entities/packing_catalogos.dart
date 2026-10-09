import 'package:equatable/equatable.dart';

/// Barcode alterno de un producto. [cantidad] > 1 cuando es el código de un
/// empaque (caja de 12, etc.): un escaneo suma esa cantidad.
class BarcodeProductoPacking extends Equatable {
  final int idMove;
  final int idProduct;
  final String barcode;
  final double cantidad;

  const BarcodeProductoPacking({
    required this.idMove,
    required this.idProduct,
    required this.barcode,
    this.cantidad = 1,
  });

  @override
  List<Object?> get props => [idMove, idProduct, barcode, cantidad];
}

/// Ubicación de muelle a la que se puede llevar un paquete.
class UbicacionMuelle extends Equatable {
  final int id;
  final String name;
  final String barcode;
  final String warehouseName;

  const UbicacionMuelle({
    required this.id,
    this.name = '',
    this.barcode = '',
    this.warehouseName = '',
  });

  @override
  List<Object?> get props => [id, name, barcode];
}

/// Permisos del usuario que afectan al packing por pedido.
class ConfigPackingUsuario extends Equatable {
  /// Escribir la cantidad a mano (botón de editar cantidad).
  final bool manualQuantityPack;

  /// Seleccionar producto a mano sin escanearlo.
  final bool manualProductSelectionPack;

  /// Confirmar la ubicación de origen a mano.
  final bool locationPackManual;

  /// Exigir el escaneo del producto.
  final bool scanProduct;

  /// Pedir foto del termómetro en productos con temperatura.
  final bool showPhotoTemperature;

  /// Ocultar el botón de validar pedido.
  final bool hideValidatePacking;

  /// Usuario de la sesión (0 = desconocido): filtro "Mis pedidos".
  final int userId;

  const ConfigPackingUsuario({
    this.manualQuantityPack = false,
    this.manualProductSelectionPack = false,
    this.locationPackManual = false,
    this.scanProduct = true,
    this.showPhotoTemperature = false,
    this.hideValidatePacking = false,
    this.userId = 0,
  });

  @override
  List<Object?> get props => [
    manualQuantityPack,
    manualProductSelectionPack,
    locationPackManual,
    scanProduct,
    showPhotoTemperature,
    hideValidatePacking,
    userId,
  ];
}

/// Lectura de temperatura hecha por IA a partir de una foto.
class TemperaturaIa extends Equatable {
  final double? temperature;
  final String unit;
  final String confidence;

  const TemperaturaIa({this.temperature, this.unit = '', this.confidence = ''});

  @override
  List<Object?> get props => [temperature, unit, confidence];
}
