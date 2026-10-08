part of 'info_rapida.dart';

/// Información detallada de un paquete en Información Rápida.
class PaqueteInfo extends InfoRapida {
  final int? id;
  final String nombre;
  final String codigoBarras;
  final double? totalProductos;
  final int? numeroProductos;
  final bool? isCertificate;
  final String? nombreAlmacen;
  final String? fechaEmpaquetado;
  final List<ProductoUbicacion> productos;

  const PaqueteInfo({
    super.actualizarVersion,
    this.id,
    required this.nombre,
    this.codigoBarras = '',
    this.totalProductos,
    this.numeroProductos,
    this.isCertificate,
    this.nombreAlmacen,
    this.fechaEmpaquetado,
    this.productos = const [],
  });

  PaqueteInfo copyWith({
    bool? actualizarVersion,
    int? id,
    String? nombre,
    String? codigoBarras,
    double? totalProductos,
    int? numeroProductos,
    bool? isCertificate,
    String? nombreAlmacen,
    String? fechaEmpaquetado,
    List<ProductoUbicacion>? productos,
  }) {
    return PaqueteInfo(
      actualizarVersion: actualizarVersion ?? this.actualizarVersion,
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      totalProductos: totalProductos ?? this.totalProductos,
      numeroProductos: numeroProductos ?? this.numeroProductos,
      isCertificate: isCertificate ?? this.isCertificate,
      nombreAlmacen: nombreAlmacen ?? this.nombreAlmacen,
      fechaEmpaquetado: fechaEmpaquetado ?? this.fechaEmpaquetado,
      productos: productos ?? this.productos,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        codigoBarras,
        totalProductos,
        numeroProductos,
        isCertificate,
        nombreAlmacen,
        fechaEmpaquetado,
        productos,
        actualizarVersion,
      ];
}
