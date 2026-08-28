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

final class RecepcionMultiusuarioPoolLoading
    extends RecepcionMultiusuarioPoolState {
  const RecepcionMultiusuarioPoolLoading();
}

final class RecepcionMultiusuarioPoolDbLoading
    extends RecepcionMultiusuarioPoolState {
  const RecepcionMultiusuarioPoolDbLoading();
}

final class RecepcionPoolLoaded extends RecepcionMultiusuarioPoolState {
  final List<RecepcionPoolItem> items;
  const RecepcionPoolLoaded(this.items);

  @override
  List<Object> get props => [items, Object()];
}

final class RecepcionMultiusuarioPoolError
    extends RecepcionMultiusuarioPoolState {
  final String message;
  const RecepcionMultiusuarioPoolError(this.message);

  @override
  List<Object> get props => [message];
}
