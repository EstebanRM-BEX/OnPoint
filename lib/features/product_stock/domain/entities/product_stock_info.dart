/// Ubicación y disponibilidad de un producto (POST /api/product/stock_info).
///
/// Con existencias llega [ubicaciones] (con lotes); sin existencias llega
/// [ultimasUbicaciones] (historial, puede venir vacío).
class ProductStockInfo {
  final String msg;
  final bool tieneExistencias;
  final StockProducto? producto;
  final double totalCantidad;
  final double totalDisponible;
  final List<StockUbicacion> ubicaciones;
  final List<StockUltimaUbicacion> ultimasUbicaciones;

  const ProductStockInfo({
    required this.msg,
    required this.tieneExistencias,
    required this.producto,
    required this.totalCantidad,
    required this.totalDisponible,
    required this.ubicaciones,
    required this.ultimasUbicaciones,
  });
}

class StockProducto {
  final int id;
  final String referencia;
  final String nombre;
  final String barcode;

  const StockProducto({
    required this.id,
    required this.referencia,
    required this.nombre,
    required this.barcode,
  });
}

class StockUbicacion {
  final int ubicacionId;
  final String ubicacionCompleta;
  final String ubicacionEspecifica;
  final String barcodeUbicacion;
  final List<StockLote> lotes;

  const StockUbicacion({
    required this.ubicacionId,
    required this.ubicacionCompleta,
    required this.ubicacionEspecifica,
    required this.barcodeUbicacion,
    required this.lotes,
  });

  double get cantidad => lotes.fold(0, (sum, l) => sum + l.cantidad);
  double get disponible =>
      lotes.fold(0, (sum, l) => sum + l.cantidadDisponible);
}

class StockLote {
  final int? loteId;
  final String lote;
  final String fechaVencimiento;
  final double cantidad;
  final double cantidadReservada;
  final double cantidadDisponible;

  const StockLote({
    required this.loteId,
    required this.lote,
    required this.fechaVencimiento,
    required this.cantidad,
    required this.cantidadReservada,
    required this.cantidadDisponible,
  });
}

class StockUltimaUbicacion {
  final int ubicacionId;
  final String ubicacionCompleta;
  final String ubicacionEspecifica;
  final String barcodeUbicacion;
  final String ultimoLote;
  final String fechaVencimiento;
  final String fechaMovimiento;
  final String documento;

  const StockUltimaUbicacion({
    required this.ubicacionId,
    required this.ubicacionCompleta,
    required this.ubicacionEspecifica,
    required this.barcodeUbicacion,
    required this.ultimoLote,
    required this.fechaVencimiento,
    required this.fechaMovimiento,
    required this.documento,
  });
}
