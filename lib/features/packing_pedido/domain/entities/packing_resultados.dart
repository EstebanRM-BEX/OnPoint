import 'package:equatable/equatable.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';

/// Resultado de sincronizar los pedidos desde Odoo.
class SyncPedidosPackResult extends Equatable {
  final List<PedidoPack> pedidos;

  /// El backend pide actualizar la versión de la app.
  final bool needUpdateVersion;

  const SyncPedidosPackResult({
    required this.pedidos,
    this.needUpdateVersion = false,
  });

  @override
  List<Object?> get props => [pedidos, needUpdateVersion];
}

/// Pedido con todo lo necesario para la pantalla de detalle, ya repartido
/// por estado.
class PedidoPackDetalle extends Equatable {
  final PedidoPack pedido;
  final List<ProductoPacking> porHacer;
  final List<ProductoPacking> listos;
  final List<ProductoPacking> empacados;
  final List<PaquetePacking> paquetes;

  /// Barcodes alternos y de empaque de los productos del pedido.
  final List<BarcodeProductoPacking> barcodes;

  const PedidoPackDetalle({
    required this.pedido,
    this.porHacer = const [],
    this.listos = const [],
    this.empacados = const [],
    this.paquetes = const [],
    this.barcodes = const [],
  });

  /// Línea "por hacer" que corresponde a un código escaneado: barcode o
  /// código del producto, o un barcode alterno de su producto.
  ProductoPacking? porHacerConCodigo(String codigo) {
    final c = codigo.trim().toLowerCase();
    if (c.isEmpty) return null;
    for (final p in porHacer) {
      if (p.barcode.toLowerCase() == c || p.productCode.toLowerCase() == c) {
        return p;
      }
    }
    final alterno = barcodes
        .where((b) => b.barcode.toLowerCase() == c)
        .map((b) => b.idProduct)
        .toSet();
    for (final p in porHacer) {
      if (alterno.contains(p.idProduct)) return p;
    }
    return null;
  }

  /// Porcentaje empacado sobre las unidades del pedido (para el aviso de
  /// backorder al validar).
  double get progresoEmpacado {
    final empacado = empacados.fold<double>(0, (s, p) => s + p.cantidadAEnviar);
    final total = pedido.numeroItems > 0
        ? pedido.numeroItems
        : todos.fold<double>(0, (s, p) => s + p.quantity);
    if (total <= 0) return 0;
    final pct = empacado / total * 100;
    return pct > 100 ? 100 : pct;
  }

  List<ProductoPacking> get todos => [...porHacer, ...listos, ...empacados];

  /// Porcentaje separado del pedido (0–100).
  double get progreso {
    final total = todos.fold<double>(0, (s, p) => s + p.quantity);
    if (total == 0) return 0;
    final separado = [
      ...listos,
      ...empacados,
    ].fold<double>(0, (s, p) => s + p.cantidadAEnviar);
    final pct = separado / total * 100;
    return pct > 100 ? 100 : pct;
  }

  @override
  List<Object?> get props => [
    pedido,
    porHacer,
    listos,
    empacados,
    paquetes,
    barcodes,
  ];
}

/// Resultado de desempacar una línea.
class DesempaqueResult extends Equatable {
  final String mensaje;

  /// El paquete quedó vacío y se eliminó.
  final bool paqueteEliminado;

  /// Odoo desempacó pero no se encontró la fila en el dispositivo: hay que
  /// refrescar desde la API.
  final bool desincronizado;

  const DesempaqueResult({
    required this.mensaje,
    this.paqueteEliminado = false,
    this.desincronizado = false,
  });

  @override
  List<Object?> get props => [mensaje, paqueteEliminado, desincronizado];
}

/// Resultado de validar el pedido (con o sin backorder).
class ValidacionPedidoResult extends Equatable {
  final String mensaje;
  final bool conBackorder;

  const ValidacionPedidoResult({
    required this.mensaje,
    required this.conBackorder,
  });

  @override
  List<Object?> get props => [mensaje, conBackorder];
}
