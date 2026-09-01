part of 'recepcion_multiusuario_pool_bloc.dart';

sealed class RecepcionMultiusuarioPoolState extends Equatable {
  const RecepcionMultiusuarioPoolState();

  @override
  List<Object> get props => [];
}

final class RecepcionMultiusuarioPoolInitial
    extends RecepcionMultiusuarioPoolState {
  const RecepcionMultiusuarioPoolInitial();
}

/// [verification] identifica a cuál de los dos fetch pertenece este loading
/// — así "Por hacer" y "Terminados" no se muestran cargando por un fetch
/// que no es el suyo (ver FetchRecepcionPoolEvent.verification).
final class RecepcionMultiusuarioPoolLoading
    extends RecepcionMultiusuarioPoolState {
  final bool verification;
  const RecepcionMultiusuarioPoolLoading(this.verification);

  @override
  List<Object> get props => [verification];
}

final class RecepcionMultiusuarioPoolDbLoading
    extends RecepcionMultiusuarioPoolState {
  const RecepcionMultiusuarioPoolDbLoading();
}

final class RecepcionPoolLoaded extends RecepcionMultiusuarioPoolState {
  final List<RecepcionPoolItem> items;
  final bool verification;
  const RecepcionPoolLoaded(this.items, this.verification);

  @override
  List<Object> get props => [items, verification, Object()];
}

final class RecepcionMultiusuarioPoolError
    extends RecepcionMultiusuarioPoolState {
  final String message;
  final bool verification;
  const RecepcionMultiusuarioPoolError(this.message, this.verification);

  @override
  List<Object> get props => [message, verification];
}
