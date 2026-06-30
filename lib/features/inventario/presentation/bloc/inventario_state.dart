// lib/features/inventario/presentation/bloc/inventario_state.dart

part of 'inventario_bloc.dart';

@immutable
sealed class InventarioState {}

class InventarioInitial extends InventarioState {}

// ─── Ubicaciones ─────────────────────────────────────────────────────────────

class LoadLocationsLoading extends InventarioState {}

class LoadLocationsSuccess extends InventarioState {
  final List<UbicacionInventario> locations;
  LoadLocationsSuccess(this.locations);
}

class LoadLocationsFailure extends InventarioState {
  final String message;
  LoadLocationsFailure(this.message);
}

// ─── Búsquedas ───────────────────────────────────────────────────────────────

class SearchLoading extends InventarioState {}

class SearchLocationSuccess extends InventarioState {
  final List<UbicacionInventario> locations;
  SearchLocationSuccess(this.locations);
}

class SearchLoteSuccess extends InventarioState {
  final List<LoteProductoInventario> locations;
  SearchLoteSuccess(this.locations);
}

class SearchProductSuccess extends InventarioState {
  final List<ProductoInventario> products;
  SearchProductSuccess(this.products);
}

class SearchFailure extends InventarioState {
  final String message;
  SearchFailure(this.message);
}

// ─── Teclado y scanner ───────────────────────────────────────────────────────

class ShowKeyboardState extends InventarioState {
  final bool showKeyboard;
  ShowKeyboardState({required this.showKeyboard});
}

class ClearScannedValueState extends InventarioState {}

class UpdateScannedValueState extends InventarioState {
  final String field;
  final String value;
  UpdateScannedValueState(this.field, this.value);
}

// ─── Validaciones de campos ───────────────────────────────────────────────────

class ValidateFieldsStateSuccess extends InventarioState {
  final bool isOk;
  ValidateFieldsStateSuccess(this.isOk);
}

class ValidateFieldsStateError extends InventarioState {
  final String message;
  ValidateFieldsStateError(this.message);
}

class ChangeLocationIsOkState extends InventarioState {
  final bool isOk;
  ChangeLocationIsOkState(this.isOk);
}

class ChangeProductIsOkState extends InventarioState {
  final bool isOk;
  ChangeProductIsOkState(this.isOk);
}

class ChangeLoteIsOkState extends InventarioState {
  final bool isOk;
  ChangeLoteIsOkState(this.isOk);
}

class ChangeQuantityIsOkState extends InventarioState {
  final bool isOk;
  ChangeQuantityIsOkState(this.isOk);
}

// ─── Limpieza ─────────────────────────────────────────────────────────────────

class CleanFieldsState extends InventarioState {}

// ─── Productos ────────────────────────────────────────────────────────────────

class GetProductsLoadingInventory extends InventarioState {}

class GetProductsSuccess extends InventarioState {
  final List<ProductoInventario> products;
  GetProductsSuccess(this.products);
}

class GetProductsLoadingBD extends InventarioState {}

class GetProductsSuccessBD extends InventarioState {
  final List<ProductoInventario> products;
  GetProductsSuccessBD(this.products);
}

class GetProductsSuccessByLocation extends InventarioState {
  final List<ProductoInventario> products;
  GetProductsSuccessByLocation(this.products);
}

class GetProductsFailureInventory extends InventarioState {
  final String message;
  GetProductsFailureInventory(this.message);
}

class GetProductsFailureByLocation extends InventarioState {
  final String message;
  GetProductsFailureByLocation(this.message);
}

// ─── Lotes ────────────────────────────────────────────────────────────────────

class GetLotesProductLoading extends InventarioState {}

class GetLotesProductSuccess extends InventarioState {
  final List<LoteProductoInventario> lotesProduct;
  GetLotesProductSuccess(this.lotesProduct);
}

class GetLotesProductFailure extends InventarioState {
  final String message;
  GetLotesProductFailure(this.message);
}

// ─── Cantidad ─────────────────────────────────────────────────────────────────

class ShowQuantityState extends InventarioState {
  final bool showQuantity;
  ShowQuantityState(this.showQuantity);
}

class ChangeQuantitySeparateStateSuccess extends InventarioState {
  final int quantity;
  ChangeQuantitySeparateStateSuccess(this.quantity);
}

class ChangeQuantitySeparateStateError extends InventarioState {
  final String message;
  ChangeQuantitySeparateStateError(this.message);
}

// ─── Barcodes ─────────────────────────────────────────────────────────────────

class BarcodesProductLoadedState extends InventarioState {
  final List<BarcodeProducto> listOfBarcodes;
  BarcodesProductLoadedState({required this.listOfBarcodes});
}

class FetchAllBarcodesSuccess extends InventarioState {
  final List<BarcodeProducto> allBarcodes;
  FetchAllBarcodesSuccess(this.allBarcodes);
}

class FetchAllBarcodesFailure extends InventarioState {
  final String message;
  FetchAllBarcodesFailure(this.message);
}

// ─── Envío ────────────────────────────────────────────────────────────────────

class SendProductLoading extends InventarioState {}

class SendProductSuccess extends InventarioState {}

class SendProductFailure extends InventarioState {
  final String message;
  SendProductFailure(this.message);
}

// ─── Crear lote ───────────────────────────────────────────────────────────────

class CreateLoteProductLoading extends InventarioState {}

class CreateLoteProductSuccess extends InventarioState {}

class CreateLoteProductFailure extends InventarioState {
  final String error;
  final int code;
  CreateLoteProductFailure(this.error, this.code);
}

// ─── Configuración ───────────────────────────────────────────────────────────

class ConfigurationLoadedInventory extends InventarioState {
  final UserConfiguration configurations;
  ConfigurationLoadedInventory(this.configurations);
}

class ConfigurationErrorInventory extends InventarioState {
  final String message;
  ConfigurationErrorInventory(this.message);
}

// ─── Filtro de almacenes ─────────────────────────────────────────────────────

class FilterUbicacionesLoading extends InventarioState {}

class FilterUbicacionesSuccess extends InventarioState {
  final List<UbicacionInventario> locations;
  FilterUbicacionesSuccess(this.locations);
}

class FilterUbicacionesFailure extends InventarioState {
  final String message;
  FilterUbicacionesFailure(this.message);
}

// ─── Conteo de productos ─────────────────────────────────────────────────────

class LoadProductosCountSuccess extends InventarioState {
  final int count;
  LoadProductosCountSuccess(this.count);
}

// ─── Progreso de sincronización ──────────────────────────────────────────────

class SyncProgressState extends InventarioState {
  final String phase;
  final int processed;
  final int total;

  SyncProgressState({
    required this.phase,
    this.processed = 0,
    this.total = 0,
  });
}

// ─── Sesión expirada (nuevo) ─────────────────────────────────────────────────

class InventarioSessionExpiredState extends InventarioState {}
