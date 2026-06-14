// lib/features/inventario/presentation/bloc/inventario_event.dart

part of 'inventario_bloc.dart';

@immutable
sealed class InventarioEvent {}

class GetLocationsEvent extends InventarioEvent {}

class SearchLocationEvent extends InventarioEvent {
  final String query;
  SearchLocationEvent(this.query);
}

// Typo preservado del legacy
class SearchLotevent extends InventarioEvent {
  final String query;
  SearchLotevent(this.query);
}

class SearchProductEvent extends InventarioEvent {
  final String query;
  SearchProductEvent(this.query);
}

class ValidateFieldsEvent extends InventarioEvent {
  final String field;
  final bool isOk;
  ValidateFieldsEvent({required this.field, required this.isOk});
}

class ChangeLocationIsOkEvent extends InventarioEvent {
  final UbicacionInventario locationSelect;
  ChangeLocationIsOkEvent(this.locationSelect);
}

class ChangeProductIsOkEvent extends InventarioEvent {
  final ProductoInventario productSelect;
  final bool isManual;
  ChangeProductIsOkEvent(this.productSelect, {this.isManual = false});
}

class ChangeIsOkQuantity extends InventarioEvent {
  final bool isQuantity;
  ChangeIsOkQuantity(this.isQuantity);
}

class GetProductsEvent extends InventarioEvent {
  final bool isDialogLoading;
  GetProductsEvent({this.isDialogLoading = false});
}

class GetProductsForDB extends InventarioEvent {}

// Typo preservado del legacy
class CleanFieldsEent extends InventarioEvent {}

class GetLotesProduct extends InventarioEvent {
  final bool isManual;
  final int idLote;
  GetLotesProduct({this.isManual = false, this.idLote = 0});
}

class SelectecLoteEvent extends InventarioEvent {
  final LoteProductoInventario lote;
  SelectecLoteEvent(this.lote);
}

class ShowQuantityEvent extends InventarioEvent {
  final bool showQuantity;
  ShowQuantityEvent(this.showQuantity);
}

class FetchBarcodesProductEvent extends InventarioEvent {}

class AddQuantitySeparate extends InventarioEvent {
  final dynamic quantity;
  final bool isOk;
  AddQuantitySeparate(this.quantity, this.isOk);
}

class ChangeQuantitySeparate extends InventarioEvent {
  final int quantity;
  ChangeQuantitySeparate(this.quantity);
}

// Typo preservado del legacy
class SendProductInventarioEnvet extends InventarioEvent {
  final dynamic cantidad;
  SendProductInventarioEnvet(this.cantidad);
}

class CreateLoteProduct extends InventarioEvent {
  final String nameLote;
  final String fechaCaducidad;
  final bool priorityExpiration;
  CreateLoteProduct(this.nameLote, this.fechaCaducidad, this.priorityExpiration);
}

class LoadConfigurationsUserInventory extends InventarioEvent {}

class FilterUbicacionesAlmacenEvent extends InventarioEvent {
  final String almacen;
  FilterUbicacionesAlmacenEvent(this.almacen);
}

class SetUbicacionFijaEvent extends InventarioEvent {
  final bool ubicacionFija;
  SetUbicacionFijaEvent(this.ubicacionFija);
}

class FetchAllBarcodesInventarioEvent extends InventarioEvent {}

class LoadProductosCountEvent extends InventarioEvent {}
