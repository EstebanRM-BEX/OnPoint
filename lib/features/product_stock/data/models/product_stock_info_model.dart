import 'package:wms_app/features/product_stock/domain/entities/product_stock_info.dart';

/// Parseo tolerante de /product/stock_info: Odoo manda `false` en lugar de
/// null y los números pueden llegar como int o double.
class ProductStockInfoModel extends ProductStockInfo {
  const ProductStockInfoModel({
    required super.msg,
    required super.tieneExistencias,
    required super.producto,
    required super.totalCantidad,
    required super.totalDisponible,
    required super.ubicaciones,
    required super.ultimasUbicaciones,
  });

  factory ProductStockInfoModel.fromJson(Map<String, dynamic> json) {
    final producto = json['producto'];
    return ProductStockInfoModel(
      msg: _str(json['msg']),
      tieneExistencias: json['tiene_existencias'] == true,
      producto: producto is Map
          ? StockProducto(
              id: _int(producto['id']),
              referencia: _str(producto['referencia']),
              nombre: _str(producto['nombre']),
              barcode: _str(producto['barcode']),
            )
          : null,
      totalCantidad: _double(json['total_cantidad']),
      totalDisponible: _double(json['total_disponible']),
      ubicaciones: _list(json['ubicaciones'], _ubicacion),
      ultimasUbicaciones: _list(json['ultimas_ubicaciones'], _ultimaUbicacion),
    );
  }

  static StockUbicacion _ubicacion(Map m) => StockUbicacion(
        ubicacionId: _int(m['ubicacion_id']),
        ubicacionCompleta: _str(m['ubicacion_completa']),
        ubicacionEspecifica: _str(m['ubicacion_especifica']),
        barcodeUbicacion: _str(m['barcode_ubicacion']),
        lotes: _list(m['lotes'], _lote),
      );

  static StockLote _lote(Map m) => StockLote(
        loteId: m['lote_id'] is num ? (m['lote_id'] as num).toInt() : null,
        lote: _str(m['lote'], fallback: 'Sin lote'),
        fechaVencimiento: _str(m['fecha_vencimiento']),
        cantidad: _double(m['cantidad']),
        cantidadReservada: _double(m['cantidad_reservada']),
        cantidadDisponible: _double(m['cantidad_disponible']),
      );

  static StockUltimaUbicacion _ultimaUbicacion(Map m) => StockUltimaUbicacion(
        ubicacionId: _int(m['ubicacion_id']),
        ubicacionCompleta: _str(m['ubicacion_completa']),
        ubicacionEspecifica: _str(m['ubicacion_especifica']),
        barcodeUbicacion: _str(m['barcode_ubicacion']),
        ultimoLote: _str(m['ultimo_lote']),
        fechaVencimiento: _str(m['fecha_vencimiento']),
        fechaMovimiento: _str(m['fecha_movimiento']),
        documento: _str(m['documento']),
      );

  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  static double _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;

  static String _str(dynamic v, {String fallback = ''}) =>
      (v == null || v == false) ? fallback : v.toString();

  static List<T> _list<T>(dynamic v, T Function(Map) fromMap) =>
      v is List ? v.whereType<Map>().map(fromMap).toList() : <T>[];
}
