import 'package:equatable/equatable.dart';

/// Estado de una línea dentro del flujo de packing.
enum EstadoProductoPacking {
  /// Pendiente de separar (tab "Por hacer").
  porHacer,

  /// Separada y certificada, todavía sin caja (tab "Listos").
  listo,

  /// Dentro de un paquete (tab "Paquetes").
  empacado,
}

/// Línea (stock.move) de un pedido de packing.
///
/// [id] es la PK local: identifica la fila exacta. Un mismo [idMove] puede
/// tener varias filas cuando el operario divide la cantidad, por eso toda
/// operación sobre una línea se hace por [id], nunca por [idMove].
class ProductoPacking extends Equatable {
  final int id;
  final int pedidoId;
  final int? batchId;
  final int idMove;
  final int idProduct;

  final String productName;
  final String productCode;
  final String barcode;

  final int? loteId;
  final String loteName;
  final String expireDate;
  final String tracking;
  final String unidades;
  final double weight;

  final int? idLocation;
  final String locationName;
  final String barcodeLocation;
  final int? idLocationDest;
  final String locationDestName;

  /// Cantidad de la línea (para una fila dividida, la parte que le toca).
  final double quantity;

  /// Cantidad separada por el operario (0 si aún no empieza).
  final double quantitySeparate;

  final EstadoProductoPacking estado;

  /// Separada escaneando (true) o empacada directo desde "Por hacer" (false).
  final bool certificado;

  /// La fila nació de dividir otra.
  final bool isProductSplit;

  final int? idPackage;
  final String packageName;

  final String observation;

  final bool manejaTemperatura;
  final double temperatura;
  final String image;
  final String imageNovedad;

  // Validaciones del escaneo.
  final bool locationOk;
  final bool productOk;
  final bool quantityOk;

  final DateTime? timeSeparateStart;

  /// Segundos que tomó separar la línea.
  final double timeSeparate;

  const ProductoPacking({
    required this.id,
    required this.pedidoId,
    this.batchId,
    required this.idMove,
    required this.idProduct,
    this.productName = '',
    this.productCode = '',
    this.barcode = '',
    this.loteId,
    this.loteName = '',
    this.expireDate = '',
    this.tracking = '',
    this.unidades = '',
    this.weight = 0,
    this.idLocation,
    this.locationName = '',
    this.barcodeLocation = '',
    this.idLocationDest,
    this.locationDestName = '',
    required this.quantity,
    this.quantitySeparate = 0,
    this.estado = EstadoProductoPacking.porHacer,
    this.certificado = false,
    this.isProductSplit = false,
    this.idPackage,
    this.packageName = '',
    this.observation = '',
    this.manejaTemperatura = false,
    this.temperatura = 0,
    this.image = '',
    this.imageNovedad = '',
    this.locationOk = false,
    this.productOk = false,
    this.quantityOk = false,
    this.timeSeparateStart,
    this.timeSeparate = 0,
  });

  bool get isPorHacer => estado == EstadoProductoPacking.porHacer;
  bool get isListo => estado == EstadoProductoPacking.listo;
  bool get isEmpacado => estado == EstadoProductoPacking.empacado;
  bool get tieneLote => loteId != null && loteId != 0;

  /// Cantidad que se envía a Odoo al empacar: lo separado (sin pasar de la
  /// cantidad de la línea) si está certificada; la línea completa si no.
  double get cantidadAEnviar {
    if (!certificado) return quantity;
    return quantitySeparate > quantity ? quantity : quantitySeparate;
  }

  /// Lo que falta por separar en esta línea.
  double get cantidadPendiente {
    final pendiente = quantity - quantitySeparate;
    return pendiente < 0 ? 0 : pendiente;
  }

  /// Coincidencia de búsqueda por barcode, código o nombre.
  bool coincideCon(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return barcode.toLowerCase().contains(q) ||
        productCode.toLowerCase().contains(q) ||
        productName.toLowerCase().contains(q);
  }

  ProductoPacking copyWith({
    double? quantity,
    double? quantitySeparate,
    EstadoProductoPacking? estado,
    bool? certificado,
    bool? isProductSplit,
    int? idPackage,
    String? packageName,
    String? observation,
    double? temperatura,
    String? image,
    String? imageNovedad,
    bool? locationOk,
    bool? productOk,
    bool? quantityOk,
    DateTime? timeSeparateStart,
    double? timeSeparate,
  }) {
    return ProductoPacking(
      id: id,
      pedidoId: pedidoId,
      batchId: batchId,
      idMove: idMove,
      idProduct: idProduct,
      productName: productName,
      productCode: productCode,
      barcode: barcode,
      loteId: loteId,
      loteName: loteName,
      expireDate: expireDate,
      tracking: tracking,
      unidades: unidades,
      weight: weight,
      idLocation: idLocation,
      locationName: locationName,
      barcodeLocation: barcodeLocation,
      idLocationDest: idLocationDest,
      locationDestName: locationDestName,
      quantity: quantity ?? this.quantity,
      quantitySeparate: quantitySeparate ?? this.quantitySeparate,
      estado: estado ?? this.estado,
      certificado: certificado ?? this.certificado,
      isProductSplit: isProductSplit ?? this.isProductSplit,
      idPackage: idPackage ?? this.idPackage,
      packageName: packageName ?? this.packageName,
      observation: observation ?? this.observation,
      manejaTemperatura: manejaTemperatura,
      temperatura: temperatura ?? this.temperatura,
      image: image ?? this.image,
      imageNovedad: imageNovedad ?? this.imageNovedad,
      locationOk: locationOk ?? this.locationOk,
      productOk: productOk ?? this.productOk,
      quantityOk: quantityOk ?? this.quantityOk,
      timeSeparateStart: timeSeparateStart ?? this.timeSeparateStart,
      timeSeparate: timeSeparate ?? this.timeSeparate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    idMove,
    quantity,
    quantitySeparate,
    estado,
    certificado,
    idPackage,
    observation,
    locationOk,
    productOk,
    quantityOk,
    temperatura,
    imageNovedad,
  ];
}
