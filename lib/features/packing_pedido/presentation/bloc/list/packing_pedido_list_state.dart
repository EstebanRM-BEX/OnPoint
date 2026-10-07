part of 'packing_pedido_list_bloc.dart';

enum ListaPackStatus { inicial, cargando, listo, error }

enum OrdenPedidosPack { prioridad, backorder, fecha, nombre }

class PackingPedidoListState extends Equatable {
  final ListaPackStatus status;
  final List<PedidoPack> pedidos;
  final String query;
  final OrdenPedidosPack orden;
  final bool ascendente;
  final bool sincronizando;
  final bool needUpdateVersion;
  final ConfigPackingUsuario config;

  /// Pedido recién asignado al usuario: la UI navega al detalle.
  final PedidoPack? pedidoAsignado;
  final PackingOperacion operacion;

  const PackingPedidoListState({
    this.status = ListaPackStatus.inicial,
    this.pedidos = const [],
    this.query = '',
    this.orden = OrdenPedidosPack.prioridad,
    this.ascendente = false,
    this.sincronizando = false,
    this.needUpdateVersion = false,
    this.config = const ConfigPackingUsuario(),
    this.pedidoAsignado,
    this.operacion = PackingOperacion.ninguna,
  });

  /// Pedidos filtrados por [query] (sin tildes) y ordenados por [orden].
  List<PedidoPack> get visibles {
    final q = normalizar(query);
    final filtrados = q.isEmpty
        ? [...pedidos]
        : pedidos.where((p) {
            return normalizar(p.name).contains(q) ||
                normalizar(p.referencia).contains(q) ||
                normalizar(p.contactoName).contains(q) ||
                normalizar(p.backorderName).contains(q);
          }).toList();

    int cmp(PedidoPack a, PedidoPack b) => switch (orden) {
      OrdenPedidosPack.prioridad => a.priority.compareTo(b.priority),
      OrdenPedidosPack.backorder =>
        (a.tieneBackorder ? 1 : 0) - (b.tieneBackorder ? 1 : 0),
      OrdenPedidosPack.fecha => (a.fechaCreacion ?? DateTime(1900)).compareTo(
        b.fechaCreacion ?? DateTime(1900),
      ),
      OrdenPedidosPack.nombre => a.name.toLowerCase().compareTo(
        b.name.toLowerCase(),
      ),
    };
    filtrados.sort((a, b) => ascendente ? cmp(a, b) : cmp(b, a));
    return filtrados;
  }

  static String normalizar(String s) {
    const tildes = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    return s.trim().toLowerCase().split('').map((c) => tildes[c] ?? c).join();
  }

  PackingPedidoListState copyWith({
    ListaPackStatus? status,
    List<PedidoPack>? pedidos,
    String? query,
    OrdenPedidosPack? orden,
    bool? ascendente,
    bool? sincronizando,
    bool? needUpdateVersion,
    ConfigPackingUsuario? config,
    PedidoPack? pedidoAsignado,
    PackingOperacion? operacion,
  }) {
    return PackingPedidoListState(
      status: status ?? this.status,
      pedidos: pedidos ?? this.pedidos,
      query: query ?? this.query,
      orden: orden ?? this.orden,
      ascendente: ascendente ?? this.ascendente,
      sincronizando: sincronizando ?? this.sincronizando,
      needUpdateVersion: needUpdateVersion ?? this.needUpdateVersion,
      config: config ?? this.config,
      pedidoAsignado: pedidoAsignado ?? this.pedidoAsignado,
      operacion: operacion ?? this.operacion,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pedidos,
    query,
    orden,
    ascendente,
    sincronizando,
    needUpdateVersion,
    config,
    pedidoAsignado,
    operacion,
  ];
}
