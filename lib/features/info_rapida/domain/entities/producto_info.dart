part of 'info_rapida.dart';

/// Información detallada de un producto en Información Rápida.
class ProductoInfo extends InfoRapida {
  final int id;
  final String nombre;
  final double? precio;
  final String referencia;
  final double? peso;
  final double? volumen;
  final String codigoBarras;
  final double? cantidadDisponible;
  final double? previsto;
  final String? categoria;
  final String? unidadMedida;
  final bool? isSticker;
  final bool? isCertificate;
  final String? fechaEmpaquetado;
  final List<UbicacionProducto> ubicaciones;
  final bool? manejoPropietario;
  final String? propietario;
  final int? idPropietario;

  const ProductoInfo({
    required this.id,
    required this.nombre,
    this.precio,
    this.referencia = '',
    this.peso,
    this.volumen,
    this.codigoBarras = '',
    this.cantidadDisponible,
    this.previsto,
    this.categoria,
    this.unidadMedida,
    this.isSticker,
    this.isCertificate,
    this.fechaEmpaquetado,
    this.ubicaciones = const [],
    this.manejoPropietario,
    this.propietario,
    this.idPropietario,
  });

  ProductoInfo copyWith({
    int? id,
    String? nombre,
    double? precio,
    String? referencia,
    double? peso,
    double? volumen,
    String? codigoBarras,
    double? cantidadDisponible,
    double? previsto,
    String? categoria,
    String? unidadMedida,
    bool? isSticker,
    bool? isCertificate,
    String? fechaEmpaquetado,
    List<UbicacionProducto>? ubicaciones,
    bool? manejoPropietario,
    String? propietario,
    int? idPropietario,
  }) {
    return ProductoInfo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      referencia: referencia ?? this.referencia,
      peso: peso ?? this.peso,
      volumen: volumen ?? this.volumen,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      cantidadDisponible: cantidadDisponible ?? this.cantidadDisponible,
      previsto: previsto ?? this.previsto,
      categoria: categoria ?? this.categoria,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      isSticker: isSticker ?? this.isSticker,
      isCertificate: isCertificate ?? this.isCertificate,
      fechaEmpaquetado: fechaEmpaquetado ?? this.fechaEmpaquetado,
      ubicaciones: ubicaciones ?? this.ubicaciones,
      manejoPropietario: manejoPropietario ?? this.manejoPropietario,
      propietario: propietario ?? this.propietario,
      idPropietario: idPropietario ?? this.idPropietario,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        precio,
        referencia,
        peso,
        volumen,
        codigoBarras,
        cantidadDisponible,
        previsto,
        categoria,
        unidadMedida,
        isSticker,
        isCertificate,
        fechaEmpaquetado,
        ubicaciones,
        manejoPropietario,
        propietario,
        idPropietario,
      ];
}

/// Registro de una ubicación donde se encuentra almacenado el producto.
class UbicacionProducto extends Equatable {
  final int? idMove;
  final int? idAlmacen;
  final int idUbicacion;
  final String ubicacion;
  final double cantidad;
  final double reservado;
  final double cantidadMano;
  final String codigoBarras;
  final String? lote;
  final int? loteId;
  final String? fechaEliminacion;
  final String? fechaCaducidad;
  final String? fechaEntrada;
  final String? unidadMedida;
  final bool? packing;
  final String? nombrePaquete;
  final String? propietario;
  final int? idPropietario;
  final bool? manejoPropietario;

  const UbicacionProducto({
    this.idMove,
    this.idAlmacen,
    required this.idUbicacion,
    this.ubicacion = '',
    this.cantidad = 0.0,
    this.reservado = 0.0,
    this.cantidadMano = 0.0,
    this.codigoBarras = '',
    this.lote,
    this.loteId,
    this.fechaEliminacion,
    this.fechaCaducidad,
    this.fechaEntrada,
    this.unidadMedida,
    this.packing,
    this.nombrePaquete,
    this.propietario,
    this.idPropietario,
    this.manejoPropietario,
  });

  @override
  List<Object?> get props => [
        idMove,
        idAlmacen,
        idUbicacion,
        ubicacion,
        cantidad,
        reservado,
        cantidadMano,
        codigoBarras,
        lote,
        loteId,
        fechaEliminacion,
        fechaCaducidad,
        fechaEntrada,
        unidadMedida,
        packing,
        nombrePaquete,
        propietario,
        idPropietario,
        manejoPropietario,
      ];
}
