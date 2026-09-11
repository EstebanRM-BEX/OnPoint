part of 'transferencia_multiusuario_pool_bloc.dart';

sealed class TransferenciaMultiusuarioPoolState extends Equatable {
  const TransferenciaMultiusuarioPoolState();

  @override
  List<Object> get props => [];
}

final class TransferenciaMultiusuarioPoolInitial
    extends TransferenciaMultiusuarioPoolState {
  const TransferenciaMultiusuarioPoolInitial();
}

/// [verification] identifica a cuál de los dos fetch pertenece este loading
/// — así "Por hacer" y "Terminados" no se muestran cargando por un fetch
/// que no es el suyo (ver FetchTransferenciaPoolEvent.verification).
final class TransferenciaMultiusuarioPoolLoading
    extends TransferenciaMultiusuarioPoolState {
  final bool verification;
  const TransferenciaMultiusuarioPoolLoading(this.verification);

  @override
  List<Object> get props => [verification];
}

final class TransferenciaPoolLoaded extends TransferenciaMultiusuarioPoolState {
  final List<TransferenciaPoolItem> items;
  final bool verification;
  const TransferenciaPoolLoaded(this.items, this.verification);

  @override
  List<Object> get props => [items, verification, Object()];
}

final class TransferenciaMultiusuarioPoolError
    extends TransferenciaMultiusuarioPoolState {
  final String message;
  final bool verification;
  const TransferenciaMultiusuarioPoolError(this.message, this.verification);

  @override
  List<Object> get props => [message, verification];
}
