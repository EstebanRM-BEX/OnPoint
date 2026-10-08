part of 'location_info_bloc.dart';

sealed class LocationInfoEvent extends Equatable {
  const LocationInfoEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializa el bloc con la entidad UbicacionInfo recibida como argumento de ruta.
class LocationInfoInicializado extends LocationInfoEvent {
  final UbicacionInfo ubicacion;

  const LocationInfoInicializado(this.ubicacion);

  @override
  List<Object?> get props => [ubicacion];
}

/// Filtra la lista de productos dentro de la ubicación por texto (nombre, barcode, lote).
class BuscarProductosUbicacionEvent extends LocationInfoEvent {
  final String query;

  const BuscarProductosUbicacionEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Ordena los productos de la ubicación por criterio: 'name', 'cantidad', 'lote'.
class OrdenarProductosUbicacionEvent extends LocationInfoEvent {
  final String criterio;
  final bool ascendente;

  const OrdenarProductosUbicacionEvent({
    required this.criterio,
    required this.ascendente,
  });

  @override
  List<Object?> get props => [criterio, ascendente];
}

/// Alterna entre modo visualización y modo edición de los datos de la ubicación.
class ToggleModoEdicionUbicacionEvent extends LocationInfoEvent {
  final bool isEditing;

  const ToggleModoEdicionUbicacionEvent(this.isEditing);

  @override
  List<Object?> get props => [isEditing];
}

/// Guarda los atributos editados de la ubicación en el backend y actualiza las maestras locales.
class GuardarEdicionUbicacionEvent extends LocationInfoEvent {
  final String nombre;
  final String barcode;

  const GuardarEdicionUbicacionEvent({
    required this.nombre,
    required this.barcode,
  });

  @override
  List<Object?> get props => [nombre, barcode];
}

/// Activa o desactiva el modo de selección masiva de productos para transferencias.
class ToggleModoSeleccionMasivaEvent extends LocationInfoEvent {
  final bool activar;

  const ToggleModoSeleccionMasivaEvent(this.activar);

  @override
  List<Object?> get props => [activar];
}

/// Selecciona o deselecciona un producto individual para la transferencia masiva,
/// validando compatibilidad de propietarios mediante PropietarioRules.
class ToggleProductoSeleccionadoEvent extends LocationInfoEvent {
  final ProductoUbicacion producto;
  final bool seleccionado;

  const ToggleProductoSeleccionadoEvent(this.producto, this.seleccionado);

  @override
  List<Object?> get props => [producto, seleccionado];
}

/// Selecciona todos los productos compatibles con el grupo de propietario activo.
class SeleccionarTodosProductosDisponiblesEvent extends LocationInfoEvent {
  const SeleccionarTodosProductosDisponiblesEvent();
}

/// Deselecciona todos los productos marcados para transferencia masiva.
class DeseleccionarTodosProductosEvent extends LocationInfoEvent {
  const DeseleccionarTodosProductosEvent();
}

/// Limpia mensajes de éxito o error temporales en la UI.
class LimpiarMensajeUbicacionEvent extends LocationInfoEvent {
  const LimpiarMensajeUbicacionEvent();
}
