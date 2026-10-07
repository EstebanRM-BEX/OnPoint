part of 'packing_packages_bloc.dart';

class PackingPackagesState extends Equatable {
  final PedidoPack? pedido;
  final List<PaquetePacking> paquetes;
  final Set<int> seleccionados;
  final int? expandido;

  final List<UbicacionMuelle> ubicaciones;
  final String queryUbicacion;
  final UbicacionMuelle? ubicacion;

  /// Sube con cada cambio confirmado por Odoo: la página recarga el detalle.
  final int cambios;
  final PackingOperacion operacion;

  const PackingPackagesState({
    this.pedido,
    this.paquetes = const [],
    this.seleccionados = const {},
    this.expandido,
    this.ubicaciones = const [],
    this.queryUbicacion = '',
    this.ubicacion,
    this.cambios = 0,
    this.operacion = PackingOperacion.ninguna,
  });

  List<PaquetePacking> get paquetesSeleccionados =>
      paquetes.where((p) => seleccionados.contains(p.id)).toList();

  List<UbicacionMuelle> get ubicacionesVisibles {
    final q = queryUbicacion.trim().toLowerCase();
    if (q.isEmpty) return ubicaciones;
    return ubicaciones
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.barcode.toLowerCase().contains(q),
        )
        .toList();
  }

  PackingPackagesState copyWith({
    PedidoPack? pedido,
    List<PaquetePacking>? paquetes,
    Set<int>? seleccionados,
    int? expandido,
    bool limpiarExpandido = false,
    List<UbicacionMuelle>? ubicaciones,
    String? queryUbicacion,
    UbicacionMuelle? ubicacion,
    bool limpiarUbicacion = false,
    int? cambios,
    PackingOperacion? operacion,
  }) {
    return PackingPackagesState(
      pedido: pedido ?? this.pedido,
      paquetes: paquetes ?? this.paquetes,
      seleccionados: seleccionados ?? this.seleccionados,
      expandido: limpiarExpandido ? null : (expandido ?? this.expandido),
      ubicaciones: ubicaciones ?? this.ubicaciones,
      queryUbicacion: queryUbicacion ?? this.queryUbicacion,
      ubicacion: limpiarUbicacion ? null : (ubicacion ?? this.ubicacion),
      cambios: cambios ?? this.cambios,
      operacion: operacion ?? this.operacion,
    );
  }

  @override
  List<Object?> get props => [
    pedido,
    paquetes,
    seleccionados,
    expandido,
    ubicaciones,
    queryUbicacion,
    ubicacion,
    cambios,
    operacion,
  ];
}
