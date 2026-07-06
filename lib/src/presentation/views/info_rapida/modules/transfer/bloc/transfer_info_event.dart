part of 'transfer_info_bloc.dart';

@immutable
sealed class TransferInfoEvent {}

class LoadLocationsTransfer extends TransferInfoEvent {}

class ValidateFieldsEventTransfer extends TransferInfoEvent {
  final String field;
  final bool isOk;
  ValidateFieldsEventTransfer({required this.field, required this.isOk});
}

class ChangeLocationDestIsOkEventTransfer extends TransferInfoEvent {
  final bool locationDestIsOk;
  final ResultUbicaciones location;
  ChangeLocationDestIsOkEventTransfer(this.locationDestIsOk, this.location);
}

class SendTransferInfo extends TransferInfoEvent {
  final dynamic quantity;
  final TransferInfoRequest request;
  SendTransferInfo(this.request, this.quantity);
}

class SearchLocationEvent extends TransferInfoEvent {
  final String query;

  SearchLocationEvent(
    this.query,
  );
}

class FilterUbicacionesEvent extends TransferInfoEvent {
  final String almacen;
  FilterUbicacionesEvent(this.almacen);
}

class CreateTransferEvent extends TransferInfoEvent {}

class SetDateStartEventTransfer extends TransferInfoEvent {}

class ShowQuantityOrderEvent extends TransferInfoEvent {}
