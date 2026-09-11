part of 'transferencia_multiusuario_location_dest_bloc.dart';

sealed class TransferenciaMultiusuarioLocationDestEvent extends Equatable {
  const TransferenciaMultiusuarioLocationDestEvent();

  @override
  List<Object?> get props => [];
}

class FetchTransferenciaUbicacionesDestEvent
    extends TransferenciaMultiusuarioLocationDestEvent {
  const FetchTransferenciaUbicacionesDestEvent();
}

class SearchTransferenciaUbicacionDestEvent
    extends TransferenciaMultiusuarioLocationDestEvent {
  const SearchTransferenciaUbicacionDestEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Filtra la lista por almacén (menú "⋮" del appbar). `almacen == null`
/// vuelve a mostrar ubicaciones de todos los almacenes.
class FilterTransferenciaUbicacionesAlmacenEvent
    extends TransferenciaMultiusuarioLocationDestEvent {
  const FilterTransferenciaUbicacionesAlmacenEvent(this.almacen);

  final String? almacen;

  @override
  List<Object?> get props => [almacen];
}
