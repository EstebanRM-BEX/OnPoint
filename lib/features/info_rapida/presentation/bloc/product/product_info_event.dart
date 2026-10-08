part of 'product_info_bloc.dart';

sealed class ProductInfoEvent extends Equatable {
  const ProductInfoEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializa el bloc con la entidad ProductoInfo recibida como argumento de ruta.
class ProductInfoInicializado extends ProductInfoEvent {
  final ProductoInfo producto;

  const ProductInfoInicializado(this.producto);

  @override
  List<Object?> get props => [producto];
}

/// Filtra la lista de ubicaciones del producto actual por texto (nombre, barcode, lote).
class BuscarUbicacionesProductoEvent extends ProductInfoEvent {
  final String query;

  const BuscarUbicacionesProductoEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Ordena las ubicaciones del producto por un criterio específico:
/// 'location' (alfabético), 'lote', 'date', 'cantidad'.
class OrdenarUbicacionesProductoEvent extends ProductInfoEvent {
  final String criterio;
  final bool ascendente;

  const OrdenarUbicacionesProductoEvent({
    required this.criterio,
    required this.ascendente,
  });

  @override
  List<Object?> get props => [criterio, ascendente];
}

/// Alterna entre el modo visualización y el modo edición de los datos del producto.
class ToggleModoEdicionProductoEvent extends ProductInfoEvent {
  final bool isEditing;

  const ToggleModoEdicionProductoEvent(this.isEditing);

  @override
  List<Object?> get props => [isEditing];
}

/// Solicita la URL pública de la imagen del producto.
class CargarImagenProductoEvent extends ProductInfoEvent {
  const CargarImagenProductoEvent();
}

/// Guarda los atributos editados del producto en el backend y actualiza las maestras locales.
class GuardarEdicionProductoEvent extends ProductInfoEvent {
  final String nombre;
  final String barcode;
  final String defaultCode;
  final String listPrice;
  final String weight;
  final String volume;

  const GuardarEdicionProductoEvent({
    required this.nombre,
    required this.barcode,
    required this.defaultCode,
    required this.listPrice,
    required this.weight,
    required this.volume,
  });

  @override
  List<Object?> get props => [
        nombre,
        barcode,
        defaultCode,
        listPrice,
        weight,
        volume,
      ];
}

/// Limpia mensajes de éxito o error temporales en la UI.
class LimpiarMensajeProductoEvent extends ProductInfoEvent {
  const LimpiarMensajeProductoEvent();
}
