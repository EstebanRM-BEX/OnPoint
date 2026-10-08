part of 'info_rapida.dart';

/// Información detallada de una ubicación en Información Rápida.
class UbicacionInfo extends InfoRapida {
  final int id;
  final String nombre;
  final String codigoBarras;
  final String? ubicacionPadre;
  final String? tipoUbicacion;
  final String? nombreAlmacen;
  final String? nombreCompleto;
  final int? numeroPedidos;
  final double? totalProductos;
  final int? numeroProductos;
  final List<ProductoUbicacion> productos;
  final String? propietario;
  final int? idPropietario;
  final bool? manejoPropietario;

  const UbicacionInfo({
    super.actualizarVersion,
    required this.id,
    required this.nombre,
    this.codigoBarras = '',
    this.ubicacionPadre,
    this.tipoUbicacion,
    this.nombreAlmacen,
    this.nombreCompleto,
    this.numeroPedidos,
    this.totalProductos,
    this.numeroProductos,
    this.productos = const [],
    this.propietario,
    this.idPropietario,
    this.manejoPropietario,
  });

  UbicacionInfo copyWith({
    bool? actualizarVersion,
    int? id,
    String? nombre,
    String? codigoBarras,
    String? ubicacionPadre,
    String? tipoUbicacion,
    String? nombreAlmacen,
    String? nombreCompleto,
    int? numeroPedidos,
    double? totalProductos,
    int? numeroProductos,
    List<ProductoUbicacion>? productos,
    String? propietario,
    int? idPropietario,
    bool? manejoPropietario,
  }) {
    return UbicacionInfo(
      actualizarVersion: actualizarVersion ?? this.actualizarVersion,
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      ubicacionPadre: ubicacionPadre ?? this.ubicacionPadre,
      tipoUbicacion: tipoUbicacion ?? this.tipoUbicacion,
      nombreAlmacen: nombreAlmacen ?? this.nombreAlmacen,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      numeroPedidos: numeroPedidos ?? this.numeroPedidos,
      totalProductos: totalProductos ?? this.totalProductos,
      numeroProductos: numeroProductos ?? this.numeroProductos,
      productos: productos ?? this.productos,
      propietario: propietario ?? this.propietario,
      idPropietario: idPropietario ?? this.idPropietario,
      manejoPropietario: manejoPropietario ?? this.manejoPropietario,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        codigoBarras,
        ubicacionPadre,
        tipoUbicacion,
        nombreAlmacen,
        nombreCompleto,
        numeroPedidos,
        totalProductos,
        numeroProductos,
        productos,
        propietario,
        idPropietario,
        manejoPropietario,
        actualizarVersion,
      ];
}

/// Registro de un producto almacenado dentro de una ubicación o paquete.
class ProductoUbicacion extends Equatable {
  final int id;
  final String producto;
  final double cantidad;
  final double reservado;
  final double cantidadMano;
  final String codigoBarras;
  final int? loteId;
  final String? lote;
  final String? unidadMedida;
  final String? pedido;
  final String? origin;
  final String? tercero;
  final String? numeroCaja;
  final String? nombreAlmacen;
  final String? operador;
  final String? fechaVencimiento;
  final bool? packing;
  final String? nombrePaquete;
  final String? propietario;
  final int? idPropietario;
  final bool? manejoPropietario;

  const ProductoUbicacion({
    required this.id,
    required this.producto,
    this.cantidad = 0.0,
    this.reservado = 0.0,
    this.cantidadMano = 0.0,
    this.codigoBarras = '',
    this.loteId,
    this.lote,
    this.unidadMedida,
    this.pedido,
    this.origin,
    this.tercero,
    this.numeroCaja,
    this.nombreAlmacen,
    this.operador,
    this.fechaVencimiento,
    this.packing,
    this.nombrePaquete,
    this.propietario,
    this.idPropietario,
    this.manejoPropietario,
  });

  ProductoUbicacion copyWith({
    int? id,
    String? producto,
    double? cantidad,
    double? reservado,
    double? cantidadMano,
    String? codigoBarras,
    int? loteId,
    String? lote,
    String? unidadMedida,
    String? pedido,
    String? origin,
    String? tercero,
    String? numeroCaja,
    String? nombreAlmacen,
    String? operador,
    String? fechaVencimiento,
    bool? packing,
    String? nombrePaquete,
    String? propietario,
    int? idPropietario,
    bool? manejoPropietario,
  }) {
    return ProductoUbicacion(
      id: id ?? this.id,
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
      reservado: reservado ?? this.reservado,
      cantidadMano: cantidadMano ?? this.cantidadMano,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      loteId: loteId ?? this.loteId,
      lote: lote ?? this.lote,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      pedido: pedido ?? this.pedido,
      origin: origin ?? this.origin,
      tercero: tercero ?? this.tercero,
      numeroCaja: numeroCaja ?? this.numeroCaja,
      nombreAlmacen: nombreAlmacen ?? this.nombreAlmacen,
      operador: operador ?? this.operador,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      packing: packing ?? this.packing,
      nombrePaquete: nombrePaquete ?? this.nombrePaquete,
      propietario: propietario ?? this.propietario,
      idPropietario: idPropietario ?? this.idPropietario,
      manejoPropietario: manejoPropietario ?? this.manejoPropietario,
    );
  }

  @override
  List<Object?> get props => [
        id,
        producto,
        cantidad,
        reservado,
        cantidadMano,
        codigoBarras,
        loteId,
        lote,
        unidadMedida,
        pedido,
        origin,
        tercero,
        numeroCaja,
        nombreAlmacen,
        operador,
        fechaVencimiento,
        packing,
        nombrePaquete,
        propietario,
        idPropietario,
        manejoPropietario,
      ];
}
