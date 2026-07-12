part of 'expedicion_detail_bloc.dart';

sealed class ExpedicionDetailState extends Equatable {
  const ExpedicionDetailState();

  @override
  List<Object> get props => [];
}

final class ExpedicionDetailInitial extends ExpedicionDetailState {
  const ExpedicionDetailInitial();
}

final class ExpedicionDetailLoading extends ExpedicionDetailState {
  const ExpedicionDetailLoading();
}

final class ExpedicionDetailLoaded extends ExpedicionDetailState {
  final ExpedicionDetail detail;
  const ExpedicionDetailLoaded(this.detail);

  @override
  List<Object> get props => [detail];
}

final class ExpedicionDetailError extends ExpedicionDetailState {
  final String message;
  const ExpedicionDetailError(this.message);

  @override
  List<Object> get props => [message];
}
