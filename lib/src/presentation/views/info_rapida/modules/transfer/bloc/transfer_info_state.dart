part of 'transfer_info_bloc.dart';

@immutable
sealed class TransferInfoState {}

final class TransferInfoInitial extends TransferInfoState {}

//*estado para actualizar el valor escaneado

class UpdateScannedValueStateTransfer extends TransferInfoState {
  final String scannedValue;
  final String scan;
  UpdateScannedValueStateTransfer(this.scannedValue, this.scan);
}

class ClearScannedValueStateTransfer extends TransferInfoState {}

class LoadLocationsLoadingTransfer extends TransferInfoState {}

class LoadLocationsSuccessTransfer extends TransferInfoState {
  final List<ResultUbicaciones> locations;
  LoadLocationsSuccessTransfer(this.locations);
}

class LoadLocationsFailureTransfer extends TransferInfoState {
  final String error;
  LoadLocationsFailureTransfer(this.error);
}

//*estado para validar campos
class ValidateFieldsStateSuccessTransfer extends TransferInfoState {
  final bool isOk;
  ValidateFieldsStateSuccessTransfer(this.isOk);
}

class ValidateFieldsStateErrorTransfer extends TransferInfoState {
  final String msg;
  ValidateFieldsStateErrorTransfer(this.msg);
}

class ChangeLocationDestIsOkStateTransfer extends TransferInfoState {
  final bool isOk;
  ChangeLocationDestIsOkStateTransfer(this.isOk);
}

//*estado para separar la cantidad
class ChangeQuantitySeparateStateSuccessTransfer extends TransferInfoState {
  final dynamic quantity;
  ChangeQuantitySeparateStateSuccessTransfer(this.quantity);
}

class SendTransferInfoLoadingTransfer extends TransferInfoState {}

class SendTransferInfoFailureTransfer extends TransferInfoState {
  final String error;
  SendTransferInfoFailureTransfer(this.error);
}

class SendTransferInfoSuccess extends TransferInfoState {
  final String msg;
  final int productId;
  SendTransferInfoSuccess(this.msg, this.productId);
}

class ShowKeyboardState extends TransferInfoState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class SearchLoading extends TransferInfoState {}

class SearchFailure extends TransferInfoState {
  final String error;
  SearchFailure(this.error);
}

class SearchLocationSuccess extends TransferInfoState {
  final List<ResultUbicaciones> locations;
  SearchLocationSuccess(this.locations);
}

class FilterUbicacionesLoading extends TransferInfoState {}

class FilterUbicacionesFailure extends TransferInfoState {
  final String error;
  FilterUbicacionesFailure(this.error);
}

class FilterUbicacionesSuccess extends TransferInfoState {
  final List<ResultUbicaciones> locations;
  FilterUbicacionesSuccess(this.locations);
}

class SetDateStartStateTransfer extends TransferInfoState {
  final String dateStart;
  SetDateStartStateTransfer(this.dateStart);
}

class ShowQuantityTransferState extends TransferInfoState {
  final bool showQuantity;
  ShowQuantityTransferState(this.showQuantity);
}
