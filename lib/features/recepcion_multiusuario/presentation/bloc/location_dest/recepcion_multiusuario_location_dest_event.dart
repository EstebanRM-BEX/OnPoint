part of 'recepcion_multiusuario_location_dest_bloc.dart';

sealed class RecepcionMultiusuarioLocationDestEvent extends Equatable {
  const RecepcionMultiusuarioLocationDestEvent();

  @override
  List<Object?> get props => [];
}

class FetchUbicacionesDestEvent extends RecepcionMultiusuarioLocationDestEvent {
  const FetchUbicacionesDestEvent();
}

class SearchUbicacionDestEvent extends RecepcionMultiusuarioLocationDestEvent {
  const SearchUbicacionDestEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Filtra la lista por almacén (menú "⋮" del appbar). `almacen == null`
/// vuelve a mostrar ubicaciones de todos los almacenes.
class FilterUbicacionesAlmacenEvent
    extends RecepcionMultiusuarioLocationDestEvent {
  const FilterUbicacionesAlmacenEvent(this.almacen);

  final String? almacen;

  @override
  List<Object?> get props => [almacen];
}
