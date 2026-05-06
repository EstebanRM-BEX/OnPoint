import 'package:wms_app/features/user/domain/entities/user_configuration.dart';

class UserConfigurationModel extends UserConfiguration {
  const UserConfigurationModel({super.result});

  factory UserConfigurationModel.fromJson(Map<String, dynamic> json) {
    return UserConfigurationModel(
      result: json['result'] != null
          ? UserConfigurationResultModel.fromJson(json['result'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': (result as UserConfigurationResultModel?)?.toJson(),
    };
  }
}

class UserConfigurationResultModel extends UserConfigurationResult {
  const UserConfigurationResultModel({super.code, super.msg, super.result});

  factory UserConfigurationResultModel.fromJson(Map<String, dynamic> json) {
    return UserConfigurationResultModel(
      code: json['code'],
      msg: json['msg'],
      result: json['result'] != null
          ? UserProfileModel.fromJson(json['result'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'msg': msg,
      'result': (result as UserProfileModel?)?.toJson(),
    };
  }
}

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    super.name,
    super.email,
    super.id,
    super.lastName,
    super.muelleOption,
    super.rol,
    super.accessProductionModule,
    super.allowMoveExcessProduction,
    super.hideValidatePicking,
    super.locationPickingManual,
    super.manualProductSelection,
    super.manualQuantity,
    super.manualSpringSelection,
    super.allowedWarehouses,
    super.returnsLocationDestOption,
    super.hideValidateReception,
    super.hideValidatePacking,
    super.hideValidateTransfer,
    super.hideExpectedQty,
    super.locationPackManual,
    super.manualProductSelectionPack,
    super.manualQuantityPack,
    super.manualSpringSelectionPack,
    super.manualProductReading,
    super.manualSourceLocation,
    super.manualSourceLocationTransfer,
    super.manualDestLocationTransfer,
    super.manualQuantityTransfer,
    super.scanProduct,
    super.scanDestinationLocationReception,
    super.allowMoveExcess,
    super.showDetallesPicking,
    super.showDetallesPack,
    super.showNextLocationsInDetails,
    super.showNextLocationsInDetailsPack,
    super.showOwnerField,
    super.countQuantityInventory,
    super.updateItemInventory,
    super.updateLocationInventory,
    super.showPhotoTemperature,
    super.locationManualInventory,
    super.manualProductSelectionInventory,
    super.manualProductSelectionTransfer,
    super.allowPriorExpirationDate,
    super.manageExpirationDateWithoutLot,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      name: json['name'],
      email: json['email'],
      lastName: json['last_name'],
      id: json['id'],
      muelleOption: json['muelle_option'],
      rol: json['rol'],
      accessProductionModule: json['access_production_module'],
      allowMoveExcessProduction: json['allow_move_excess_production'],
      hideValidatePicking: json['hide_validate_picking'],
      locationPickingManual: json['location_picking_manual'],
      manualProductSelection: json['manual_product_selection'],
      manualQuantity: json['manual_quantity'],
      manualSpringSelection: json['manual_spring_selection'],
      returnsLocationDestOption: json['returns_location_dest_option'],
      allowedWarehouses: json['allowed_warehouses'] != null
          ? (json['allowed_warehouses'] as List)
              .map((e) => AllowedWarehouseModel.fromJson(e))
              .toList()
          : null,
      hideValidateReception: json['hide_validate_reception'],
      hideValidatePacking: json['hide_validate_packing'],
      hideValidateTransfer: json['hide_validate_transfer'],
      hideExpectedQty: json['hide_expected_qty'],
      locationPackManual: json['location_pack_manual'],
      manualProductSelectionPack: json['manual_product_selection_pack'],
      manualQuantityPack: json['manual_quantity_pack'],
      manualSpringSelectionPack: json['manual_spring_selection_pack'],
      manualProductReading: json['manual_product_reading'],
      manualSourceLocation: json['manual_source_location'],
      manualSourceLocationTransfer: json['manual_source_location_transfer'],
      manualDestLocationTransfer: json['manual_dest_location_transfer'],
      manualQuantityTransfer: json['manual_quantity_transfer'],
      scanProduct: json['scan_product'],
      scanDestinationLocationReception:
          json['scan_destination_location_reception'],
      allowMoveExcess: json['allow_move_excess'],
      showDetallesPicking: json['show_detalles_picking'],
      showDetallesPack: json['show_detalles_pack'],
      showNextLocationsInDetails: json['show_next_locations_in_details'],
      showNextLocationsInDetailsPack:
          json['show_next_locations_in_details_pack'],
      showOwnerField: json['show_owner_field'],
      countQuantityInventory: json['count_quantity_inventory'],
      updateItemInventory: json['update_item_inventory'],
      updateLocationInventory: json['update_location_inventory'],
      showPhotoTemperature: json['show_photo_temperature'],
      locationManualInventory: json['location_manual_inventory'],
      manualProductSelectionInventory:
          json['manual_product_selection_inventory'],
      manualProductSelectionTransfer: json['manual_product_selection_transfer'],
      allowPriorExpirationDate: json['allow_prior_expiration_date'],
      manageExpirationDateWithoutLot:
          json['manage_expiration_date_without_lot'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'rol': rol,
      'id': id,
      'last_name': lastName,
      'muelle_option': muelleOption,
      'access_production_module': accessProductionModule,
      'allow_move_excess_production': allowMoveExcessProduction,
      'hide_validate_picking': hideValidatePicking,
      'location_picking_manual': locationPickingManual,
      'manual_product_selection': manualProductSelection,
      'manual_quantity': manualQuantity,
      'manual_spring_selection': manualSpringSelection,
      'returns_location_dest_option': returnsLocationDestOption,
      'allowed_warehouses': allowedWarehouses
          ?.map((e) => (e as AllowedWarehouseModel).toJson())
          .toList(),
      'hide_validate_reception': hideValidateReception,
      'hide_validate_packing': hideValidatePacking,
      'hide_validate_transfer': hideValidateTransfer,
      'hide_expected_qty': hideExpectedQty,
      'location_pack_manual': locationPackManual,
      'manual_product_selection_pack': manualProductSelectionPack,
      'manual_quantity_pack': manualQuantityPack,
      'manual_spring_selection_pack': manualSpringSelectionPack,
      'manual_product_reading': manualProductReading,
      'manual_source_location': manualSourceLocation,
      'manual_source_location_transfer': manualSourceLocationTransfer,
      'manual_dest_location_transfer': manualDestLocationTransfer,
      'manual_quantity_transfer': manualQuantityTransfer,
      'scan_product': scanProduct,
      'scan_destination_location_reception': scanDestinationLocationReception,
      'allow_move_excess': allowMoveExcess,
      'show_detalles_picking': showDetallesPicking,
      'show_detalles_pack': showDetallesPack,
      'show_next_locations_in_details': showNextLocationsInDetails,
      'show_next_locations_in_details_pack': showNextLocationsInDetailsPack,
      'show_owner_field': showOwnerField,
      'count_quantity_inventory': countQuantityInventory,
      'update_item_inventory': updateItemInventory,
      'update_location_inventory': updateLocationInventory,
      'show_photo_temperature': showPhotoTemperature,
      'location_manual_inventory': locationManualInventory,
      'manual_product_selection_inventory': manualProductSelectionInventory,
      'manual_product_selection_transfer': manualProductSelectionTransfer,
      'allow_prior_expiration_date': allowPriorExpirationDate,
      "manage_expiration_date_without_lot": manageExpirationDateWithoutLot,
    };
  }
}

class AllowedWarehouseModel extends AllowedWarehouse {
  const AllowedWarehouseModel({super.id, super.name});

  factory AllowedWarehouseModel.fromJson(Map<String, dynamic> json) {
    return AllowedWarehouseModel(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
