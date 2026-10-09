import 'package:equatable/equatable.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';

/// Caja creada en Odoo para un pedido.
class PaquetePacking extends Equatable {
  final int id;
  final int pedidoId;
  final int? batchId;
  final String name;
  final String packingBarcode;

  /// Nombre correlativo de la caja dentro del pedido ("Caja3").
  final String consecutivo;

  final int cantidadProductos;
  final bool isSticker;
  final bool isCertificate;
  final String typePaquete;
  final double peso;

  final int? locationDestId;
  final String locationDestName;
  final String locationDestBarcode;

  final List<ProductoPacking> productos;

  const PaquetePacking({
    required this.id,
    required this.pedidoId,
    this.batchId,
    this.name = '',
    this.packingBarcode = '',
    this.consecutivo = '',
    this.cantidadProductos = 0,
    this.isSticker = false,
    this.isCertificate = false,
    this.typePaquete = '',
    this.peso = 0,
    this.locationDestId,
    this.locationDestName = '',
    this.locationDestBarcode = '',
    this.productos = const [],
  });

  /// Número al final del consecutivo ("Caja3" → 3), null si no tiene.
  int? get numeroConsecutivo {
    final match = RegExp(r'(\d+)$').firstMatch(consecutivo);
    return match == null ? null : int.parse(match.group(1)!);
  }

  bool get tieneUbicacionDestino =>
      locationDestId != null && locationDestId != 0;

  /// Coincide por nombre o por barcode del paquete (sin distinguir mayúsculas).
  bool coincideCon(String valor) {
    final v = valor.trim().toLowerCase();
    return v.isNotEmpty &&
        (name.toLowerCase() == v || packingBarcode.toLowerCase() == v);
  }

  PaquetePacking copyWith({
    String? consecutivo,
    int? cantidadProductos,
    int? locationDestId,
    String? locationDestName,
    String? locationDestBarcode,
    List<ProductoPacking>? productos,
  }) {
    return PaquetePacking(
      id: id,
      pedidoId: pedidoId,
      batchId: batchId,
      name: name,
      packingBarcode: packingBarcode,
      consecutivo: consecutivo ?? this.consecutivo,
      cantidadProductos: cantidadProductos ?? this.cantidadProductos,
      isSticker: isSticker,
      isCertificate: isCertificate,
      typePaquete: typePaquete,
      peso: peso,
      locationDestId: locationDestId ?? this.locationDestId,
      locationDestName: locationDestName ?? this.locationDestName,
      locationDestBarcode: locationDestBarcode ?? this.locationDestBarcode,
      productos: productos ?? this.productos,
    );
  }

  @override
  List<Object?> get props => [
    id,
    consecutivo,
    cantidadProductos,
    peso,
    locationDestId,
    productos,
  ];
}
