part of 'packing_pedido_list_bloc.dart';

enum ListaPackStatus { inicial, cargando, listo, error }

enum OrdenPedidosPack { prioridad, backorder, fecha, nombre }

class PackingPedidoListState extends Equatable {
  final ListaPackStatus status;
  final List<PedidoPack> pedidos;
  final String query;

  /// Filtro por propietario (null = todos).
  final String? propietario;
  final OrdenPedidosPack orden;
  final bool ascendente;
  final bool sincronizando;
  final bool needUpdateVersion;
  final ConfigPackingUsuario config;

  /// Pedido listo para abrir (asignado o con el inicio registrado): la UI
  /// navega al detalle cuando la operación 'abrir' termina en éxito.
  final PedidoPack? pedidoAbierto;
  final PackingOperacion operacion;

  const PackingPedidoListState({
    this.status = ListaPackStatus.inicial,
    this.pedidos = const [],
    this.query = '',
    this.propietario,
    this.orden = OrdenPedidosPack.prioridad,
    this.ascendente = false,
    this.sincronizando = false,
    this.needUpdateVersion = false,
    this.config = const ConfigPackingUsuario(),
    this.pedidoAbierto,
    this.operacion = PackingOperacion.ninguna,
  });

  /// Pedidos filtrados por [query] (sin tildes) y ordenados por [orden].
  List<PedidoPack> get visibles {
    final q = normalizar(query);
    final base = pedidos
        .where((p) => !p.isTerminate)
        .where((p) => propietario == null || p.propietario == propietario);
    final filtrados = q.isEmpty
        ? base.toList()
        : base.where((p) {
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

  /// Propietarios de los pedidos activos, para el filtro.
  List<String> get propietarios =>
      (pedidos
          .where((p) => !p.isTerminate && p.propietario.isNotEmpty)
          .map((p) => p.propietario)
          .toSet()
          .toList()
        ..sort());

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
    String? propietario,
    bool limpiarPropietario = false,
    OrdenPedidosPack? orden,
    bool? ascendente,
    bool? sincronizando,
    bool? needUpdateVersion,
    ConfigPackingUsuario? config,
    PedidoPack? pedidoAbierto,
    PackingOperacion? operacion,
  }) {
    return PackingPedidoListState(
      status: status ?? this.status,
      pedidos: pedidos ?? this.pedidos,
      query: query ?? this.query,
      propietario: limpiarPropietario
          ? null
          : (propietario ?? this.propietario),
      orden: orden ?? this.orden,
      ascendente: ascendente ?? this.ascendente,
      sincronizando: sincronizando ?? this.sincronizando,
      needUpdateVersion: needUpdateVersion ?? this.needUpdateVersion,
      config: config ?? this.config,
      pedidoAbierto: pedidoAbierto ?? this.pedidoAbierto,
      operacion: operacion ?? this.operacion,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pedidos,
    query,
    propietario,
    orden,
    ascendente,
    sincronizando,
    needUpdateVersion,
    config,
    pedidoAbierto,
    operacion,
  ];
}
