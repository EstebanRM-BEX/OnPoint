part of 'transferencia_multiusuario_location_dest_bloc.dart';

sealed class TransferenciaMultiusuarioLocationDestState extends Equatable {
  const TransferenciaMultiusuarioLocationDestState();

  @override
  List<Object?> get props => [];
}

class TransferenciaMultiusuarioLocationDestInitial
    extends TransferenciaMultiusuarioLocationDestState {
  const TransferenciaMultiusuarioLocationDestInitial();
}

class TransferenciaMultiusuarioLocationDestLoading
    extends TransferenciaMultiusuarioLocationDestState {
  const TransferenciaMultiusuarioLocationDestLoading();
}

class TransferenciaMultiusuarioLocationDestLoaded
    extends TransferenciaMultiusuarioLocationDestState {
  const TransferenciaMultiusuarioLocationDestLoaded(
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

class TransferenciaMultiusuarioLocationDestError
    extends TransferenciaMultiusuarioLocationDestState {
  const TransferenciaMultiusuarioLocationDestError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
