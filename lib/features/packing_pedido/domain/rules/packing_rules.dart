import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';

/// Cómo queda una cantidad ingresada frente a la cantidad de la línea.
enum ValidacionCantidad {
  /// Cero, negativa o no numérica.
  invalida,

  /// Igual a la cantidad de la línea: se separa completa.
  completa,

  /// Menor: se acepta con novedad (backorder) o se divide.
  parcial,

  /// Mayor a la cantidad de la línea: no se permite.
  excede,
}

/// Reglas del packing por pedido. Funciones puras: sin BD ni red, para que
/// los use cases y los blocs las compartan y se puedan probar aisladas.
class PackingRules {
  const PackingRules._();

  /// Tolerancia para comparar cantidades decimales.
  static const double epsilon = 1e-6;

  static ValidacionCantidad evaluarCantidad(
    ProductoPacking producto,
    double cantidad,
  ) {
    if (cantidad.isNaN || cantidad <= 0) return ValidacionCantidad.invalida;
    final diff = cantidad - producto.quantity;
    if (diff.abs() < epsilon) return ValidacionCantidad.completa;
    return diff < 0 ? ValidacionCantidad.parcial : ValidacionCantidad.excede;
  }

  /// Un escaneo suma [incremento] a lo ya separado ([actual]) solo si no se
  /// pasa de la cantidad de la línea.
  static bool puedeSumarEscaneo(
    ProductoPacking producto, {
    required double actual,
    required double incremento,
  }) {
    if (incremento <= 0) return false;
    return actual + incremento <= producto.quantity + epsilon;
  }

  /// null si se puede dividir; si no, el motivo.
  static String? validarDivision(ProductoPacking producto, double cantidad) {
    if (!producto.isPorHacer) {
      return 'Solo se puede dividir un producto pendiente por hacer';
    }
    if (cantidad.isNaN || cantidad <= 0) {
      return 'La cantidad a dividir debe ser mayor a cero';
    }
    if (cantidad >= producto.quantity - epsilon) {
      return 'La cantidad a dividir debe ser menor a ${producto.quantity}';
    }
    return null;
  }

  /// null si se puede separar con [cantidad] (completa o parcial con
  /// novedad); si no, el motivo.
  static String? validarSeparacion(ProductoPacking producto, double cantidad) {
    if (!producto.isPorHacer) {
      return 'El producto ya fue separado';
    }
    switch (evaluarCantidad(producto, cantidad)) {
      case ValidacionCantidad.invalida:
        return 'La cantidad debe ser mayor a cero';
      case ValidacionCantidad.excede:
        return 'La cantidad no puede ser mayor a ${producto.quantity}';
      case ValidacionCantidad.completa:
      case ValidacionCantidad.parcial:
        return null;
    }
  }

  /// null si las líneas se pueden meter en una caja; si no, el motivo.
  ///
  /// [certificado] = viene de "Listos" (true) o directo de "Por hacer" (false).
  static String? validarEmpaque(
    List<ProductoPacking> productos, {
    required bool certificado,
  }) {
    if (productos.isEmpty) return 'Seleccione al menos un producto';

    final pedidoId = productos.first.pedidoId;
    if (productos.any((p) => p.pedidoId != pedidoId)) {
      return 'Todos los productos deben ser del mismo pedido';
    }
    if (productos.any((p) => p.isEmpacado)) {
      return 'Hay productos que ya están en un paquete';
    }
    final estadoEsperado = certificado
        ? EstadoProductoPacking.listo
        : EstadoProductoPacking.porHacer;
    if (productos.any((p) => p.estado != estadoEsperado)) {
      return certificado
          ? 'Solo se pueden empacar productos listos'
          : 'Solo se pueden empacar productos por hacer';
    }
    final sinCantidad = productos.where((p) => p.cantidadAEnviar <= 0);
    if (sinCantidad.isNotEmpty) {
      return 'El producto ${sinCantidad.first.productName} no tiene cantidad '
          'para empacar';
    }
    return null;
  }

  /// Corre una posición los consecutivos de las cajas posteriores a la
  /// eliminada ("Caja3" → "Caja2"). Devuelve solo los paquetes que cambian,
  /// conservando el resto de sus datos.
  static List<PaquetePacking> recalcularConsecutivos(
    List<PaquetePacking> paquetes, {
    required PaquetePacking eliminado,
  }) {
    final ref = eliminado.numeroConsecutivo;
    if (ref == null) return const [];

    return [
      for (final p in paquetes)
        if (p.id != eliminado.id &&
            p.numeroConsecutivo != null &&
            p.numeroConsecutivo! > ref)
          p.copyWith(
            consecutivo: p.consecutivo.replaceFirst(
              RegExp(r'\d+$'),
              '${p.numeroConsecutivo! - 1}',
            ),
          ),
    ];
  }
}
