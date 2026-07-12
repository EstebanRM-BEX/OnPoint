part of 'expedicion_detail_bloc.dart';

sealed class ExpedicionDetailEvent extends Equatable {
  const ExpedicionDetailEvent();

  @override
  List<Object> get props => [];
}

class LoadExpedicionDetailEvent extends ExpedicionDetailEvent {
  final int expeditionId;
  const LoadExpedicionDetailEvent(this.expeditionId);

  @override
  List<Object> get props => [expeditionId];
}
