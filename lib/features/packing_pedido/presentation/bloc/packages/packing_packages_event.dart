part of 'packing_packages_bloc.dart';

sealed class PackingPackagesEvent extends Equatable {
  const PackingPackagesEvent();

  @override
  List<Object?> get props => [];
}

/// Pedido y paquetes vigentes (los manda la página desde el detalle).
class PaquetesPackActualizados extends PackingPackagesEvent {
  final PedidoPack pedido;
  final List<PaquetePacking> paquetes;
  const PaquetesPackActualizados(this.pedido, this.paquetes);

  @override
  List<Object?> get props => [pedido, paquetes];
}

class PaquetePackSeleccionado extends PackingPackagesEvent {
  final int paqueteId;
  final bool seleccionado;
  const PaquetePackSeleccionado(this.paqueteId, {required this.seleccionado});

  @override
  List<Object?> get props => [paqueteId, seleccionado];
}

class SeleccionPaquetesPackReemplazada extends PackingPackagesEvent {
  final Iterable<int> paqueteIds;
  const SeleccionPaquetesPackReemplazada(this.paqueteIds);

  @override
  List<Object?> get props => [paqueteIds.toList()];
}

/// Barcode o nombre de una caja leído por el escáner.
class PaquetePackEscaneado extends PackingPackagesEvent {
  final String valor;
  const PaquetePackEscaneado(this.valor);

  @override
  List<Object?> get props => [valor];
}

/// Abre/cierra el detalle de una caja (null o la misma = cerrar).
class PaquetePackExpandido extends PackingPackagesEvent {
  final int? paqueteId;
  const PaquetePackExpandido(this.paqueteId);

  @override
  List<Object?> get props => [paqueteId];
}

class ProductoPackDesempacado extends PackingPackagesEvent {
  final PaquetePacking paquete;
  final ProductoPacking producto;
  const ProductoPackDesempacado(this.paquete, this.producto);

  @override
  List<Object?> get props => [paquete, producto];
}

class PaquetePackEliminado extends PackingPackagesEvent {
  final PaquetePacking paquete;
  const PaquetePackEliminado(this.paquete);

  @override
  List<Object?> get props => [paquete];
}

class PesoPaquetePackEditado extends PackingPackagesEvent {
  final PaquetePacking paquete;
  final double peso;
  const PesoPaquetePackEditado(this.paquete, this.peso);

  @override
  List<Object?> get props => [paquete, peso];
}

class UbicacionesMuellePackCargadas extends PackingPackagesEvent {
  const UbicacionesMuellePackCargadas();
}

class BusquedaUbicacionPackCambiada extends PackingPackagesEvent {
  final String query;
  const BusquedaUbicacionPackCambiada(this.query);

  @override
  List<Object?> get props => [query];
}

class UbicacionMuellePackElegida extends PackingPackagesEvent {
  final UbicacionMuelle ubicacion;
  const UbicacionMuellePackElegida(this.ubicacion);

  @override
  List<Object?> get props => [ubicacion];
}

class UbicacionMuellePackEscaneada extends PackingPackagesEvent {
  final String valor;
  const UbicacionMuellePackEscaneada(this.valor);

  @override
  List<Object?> get props => [valor];
}

/// Lleva los paquetes seleccionados a la ubicación elegida.
class UbicacionPaquetesPackAsignada extends PackingPackagesEvent {
  const UbicacionPaquetesPackAsignada();
}
