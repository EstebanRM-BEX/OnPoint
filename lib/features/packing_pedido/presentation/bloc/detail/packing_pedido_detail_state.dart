part of 'packing_pedido_detail_bloc.dart';

enum DetallePackStatus { inicial, cargando, listo, error }

class PackingPedidoDetailState extends Equatable {
  final int? pedidoId;
  final DetallePackStatus status;
  final PedidoPackDetalle? detalle;

  /// Búsqueda en "Por hacer" (barcode, código o nombre).
  final String query;

  /// PKs de las líneas seleccionadas para empacar (de "Por hacer" o "Listos").
  final Set<int> seleccionados;
  final bool isSticker;
  final ConfigPackingUsuario config;
  final PackingOperacion operacion;

  /// Indica si se está sincronizando el detalle en segundo plano desde el servidor
  /// (p. ej. al entrar a la pestaña "Preparado").
  final bool cargandoRemoto;

  const PackingPedidoDetailState({
    this.pedidoId,
    this.status = DetallePackStatus.inicial,
    this.detalle,
    this.query = '',
    this.seleccionados = const {},
    this.isSticker = false,
    this.config = const ConfigPackingUsuario(),
    this.operacion = PackingOperacion.ninguna,
    this.cargandoRemoto = false,
  });

  List<ProductoPacking> get porHacerVisibles => (detalle?.porHacer ?? const [])
      .where((p) => p.coincideCon(query))
      .toList();

  List<ProductoPacking> get seleccionadosPorHacer =>
      (detalle?.porHacer ?? const <ProductoPacking>[])
          .where((p) => seleccionados.contains(p.id))
          .toList();

  List<ProductoPacking> get seleccionadosListos =>
      (detalle?.listos ?? const <ProductoPacking>[])
          .where((p) => seleccionados.contains(p.id))
          .toList();

  bool get pedidoTerminado => detalle?.pedido.isTerminate ?? false;

  PackingPedidoDetailState copyWith({
    DetallePackStatus? status,
    PedidoPackDetalle? detalle,
    String? query,
    Set<int>? seleccionados,
    bool? isSticker,
    ConfigPackingUsuario? config,
    PackingOperacion? operacion,
    bool? cargandoRemoto,
  }) {
    return PackingPedidoDetailState(
      pedidoId: pedidoId,
      status: status ?? this.status,
      detalle: detalle ?? this.detalle,
      query: query ?? this.query,
      seleccionados: seleccionados ?? this.seleccionados,
      isSticker: isSticker ?? this.isSticker,
      config: config ?? this.config,
      operacion: operacion ?? this.operacion,
      cargandoRemoto: cargandoRemoto ?? this.cargandoRemoto,
    );
  }

  @override
  List<Object?> get props => [
    pedidoId,
    status,
    detalle,
    query,
    seleccionados,
    isSticker,
    config,
    operacion,
    cargandoRemoto,
  ];
}
