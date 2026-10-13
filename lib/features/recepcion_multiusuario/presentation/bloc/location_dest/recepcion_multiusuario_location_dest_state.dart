part of 'recepcion_multiusuario_location_dest_bloc.dart';

sealed class RecepcionMultiusuarioLocationDestState extends Equatable {
  const RecepcionMultiusuarioLocationDestState();

  @override
  List<Object?> get props => [];
}

class RecepcionMultiusuarioLocationDestInitial
    extends RecepcionMultiusuarioLocationDestState {
  const RecepcionMultiusuarioLocationDestInitial();
}

class RecepcionMultiusuarioLocationDestLoading
    extends RecepcionMultiusuarioLocationDestState {
  const RecepcionMultiusuarioLocationDestLoading();
}

class RecepcionMultiusuarioLocationDestLoaded
    extends RecepcionMultiusuarioLocationDestState {
  const RecepcionMultiusuarioLocationDestLoaded(
    this.ubicaciones, {
    this.hayMas = false,
    this.version = 0,
  });

  /// Páginas cargadas de la búsqueda vigente.
  final List<ResultUbicaciones> ubicaciones;

  /// Hay más páginas por cargar.
  final bool hayMas;

  /// Sube con cada búsqueda o filtro nuevo (no al cargar más): la pantalla
  /// descarta la selección por índice cuando cambia.
  final int version;

  @override
  List<Object?> get props => [ubicaciones, hayMas, version];
}

class RecepcionMultiusuarioLocationDestError
    extends RecepcionMultiusuarioLocationDestState {
  const RecepcionMultiusuarioLocationDestError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
