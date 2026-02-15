class UserConfiguration {
  final UserConfigurationResult? result;

  const UserConfiguration({this.result});

  @override
  List<Object?> get props => [result];
}

class UserConfigurationResult {
  final int? code;
  final String? msg;
  final UserProfile? result;

  const UserConfigurationResult({this.code, this.msg, this.result});
}

class UserProfile {
  final String? name;
  final String? email;
  final int? id;
  final String? lastName;
  final String? rol;
  final String? muelleOption;
  final bool? accessProductionModule;
  final bool? allowMoveExcessProduction;
  final bool? hideValidatePicking;
  final bool? locationPickingManual;
  final bool? manualProductSelection;
  final bool? manualQuantity;
  final bool? manualSpringSelection;
  final List<AllowedWarehouse>? allowedWarehouses;
  final bool? showDetallesPicking;
  final bool? showNextLocationsInDetails;
  final bool? locationPackManual;
  final bool? showDetallesPack;
  final bool? showNextLocationsInDetailsPack;
  final bool? manualProductSelectionPack;
  final bool? manualQuantityPack;
  final bool? manualSpringSelectionPack;
  final bool? scanProduct;
  final bool? allowMoveExcess;
  final bool? hideExpectedQty;
  final bool? manualProductReading;
  final bool? manualSourceLocation;
  final bool? showOwnerField;
  final bool? manualProductSelectionTransfer;
  final bool? manualSourceLocationTransfer;
  final bool? manualDestLocationTransfer;
  final bool? manualQuantityTransfer;
  final bool? countQuantityInventory;

  final bool? hideValidateTransfer;
  final bool? hideValidateReception;
  final bool? hideValidatePacking;

  final bool? updateItemInventory;

  final bool? scanDestinationLocationReception;
  final bool? updateLocationInventory;
  final bool? showPhotoTemperature;

  final String? returnsLocationDestOption;
  final bool? locationManualInventory;
  final bool? manualProductSelectionInventory;

  const UserProfile({
    this.id,
    this.lastName,
    this.muelleOption,
    this.name,
    this.email,
    this.rol,
    this.accessProductionModule,
    this.allowMoveExcessProduction,
    this.hideValidatePicking,
    this.locationPickingManual,
    this.manualProductSelection,
    this.manualQuantity,
    this.manualSpringSelection,
    this.allowedWarehouses,
    this.showDetallesPicking,
    this.showNextLocationsInDetails,
    this.locationPackManual,
    this.showDetallesPack,
    this.showNextLocationsInDetailsPack,
    this.manualProductSelectionPack,
    this.manualQuantityPack,
    this.manualSpringSelectionPack,
    this.scanProduct,
    this.allowMoveExcess,
    this.hideExpectedQty,
    this.manualProductReading,
    this.manualSourceLocation,
    this.showOwnerField,
    this.manualProductSelectionTransfer,
    this.manualSourceLocationTransfer,
    this.manualDestLocationTransfer,
    this.manualQuantityTransfer,
    this.countQuantityInventory,
    this.hideValidateTransfer,
    this.hideValidateReception,
    this.hideValidatePacking,
    this.updateItemInventory,
    this.scanDestinationLocationReception,
    this.updateLocationInventory,
    this.showPhotoTemperature,
    this.returnsLocationDestOption,
    this.locationManualInventory,
    this.manualProductSelectionInventory,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        rol,
        accessProductionModule,
        allowMoveExcessProduction,
        hideValidatePicking,
        locationPickingManual,
        manualProductSelection,
        manualQuantity,
        manualSpringSelection,
        allowedWarehouses,
        showDetallesPicking,
        showNextLocationsInDetails,
        locationPackManual,
        showDetallesPack,
        showNextLocationsInDetailsPack,
        manualProductSelectionPack,
        manualQuantityPack,
        manualSpringSelectionPack,
        scanProduct,
        allowMoveExcess,
        hideExpectedQty,
        manualProductReading,
        manualSourceLocation,
        showOwnerField,
        manualProductSelectionTransfer,
        manualSourceLocationTransfer,
        manualDestLocationTransfer,
        manualQuantityTransfer,
        countQuantityInventory,
        hideValidateTransfer,
        hideValidateReception,
        hideValidatePacking,
        updateItemInventory,
        scanDestinationLocationReception,
        updateLocationInventory,
        showPhotoTemperature,
        returnsLocationDestOption,
        locationManualInventory,
        manualProductSelectionInventory,
      ];
}

class AllowedWarehouse {
  final int? id;
  final String? name;
  const AllowedWarehouse({this.id, this.name});
}
