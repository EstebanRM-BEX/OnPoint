import 'package:wms_app/features/user/domain/entities/user_configuration.dart';

/// Odoo no es consistente con los booleanos: un mismo permiso puede llegar como
/// `true`/`false` (bool), como `1`/`0` (int) o incluso como `"true"`/`"1"`
/// (string). Asignar un `int` a un campo `bool?` lanza un error de tipo que
/// tumba TODO el parseo de configuraciones y deja al usuario sin permisos.
/// Este helper normaliza cualquiera de esas formas a `bool?`.
bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0' || v == '') return false;
  }
  return null;
}

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
    super.hideValidateExpedition,
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
    // show_button_validate_cluster_picking
    super.showButtonValidateClusterPicking,
    // allow_validate_multiple
    super.allowValidateMultiple,
    // hide_validate_item_expedition
    super.hideValidateItemExpedition,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      name: json['name'],
      email: json['email'],
      lastName: json['last_name'],
      id: json['id'],
      muelleOption: json['muelle_option'],
      rol: json['rol'],
      accessProductionModule: _asBool(json['access_production_module']),
      allowMoveExcessProduction: _asBool(json['allow_move_excess_production']),
      hideValidatePicking: _asBool(json['hide_validate_picking']),
      locationPickingManual: _asBool(json['location_picking_manual']),
      manualProductSelection: _asBool(json['manual_product_selection']),
      manualQuantity: _asBool(json['manual_quantity']),
      manualSpringSelection: _asBool(json['manual_spring_selection']),
      returnsLocationDestOption: json['returns_location_dest_option'],
      allowedWarehouses: json['allowed_warehouses'] != null
          ? (json['allowed_warehouses'] as List)
              .map((e) => AllowedWarehouseModel.fromJson(e))
              .toList()
          : null,
      hideValidateReception: _asBool(json['hide_validate_reception']),
      hideValidatePacking: _asBool(json['hide_validate_packing']),
      hideValidateExpedition: _asBool(json['hide_validate_expedition']),
      hideValidateTransfer: _asBool(json['hide_validate_transfer']),
      hideExpectedQty: _asBool(json['hide_expected_qty']),
      locationPackManual: _asBool(json['location_pack_manual']),
      manualProductSelectionPack: _asBool(json['manual_product_selection_pack']),
      manualQuantityPack: _asBool(json['manual_quantity_pack']),
      manualSpringSelectionPack: _asBool(json['manual_spring_selection_pack']),
      manualProductReading: _asBool(json['manual_product_reading']),
      manualSourceLocation: _asBool(json['manual_source_location']),
      manualSourceLocationTransfer:
          _asBool(json['manual_source_location_transfer']),
      manualDestLocationTransfer:
          _asBool(json['manual_dest_location_transfer']),
      manualQuantityTransfer: _asBool(json['manual_quantity_transfer']),
      scanProduct: _asBool(json['scan_product']),
      scanDestinationLocationReception:
          _asBool(json['scan_destination_location_reception']),
      allowMoveExcess: _asBool(json['allow_move_excess']),
      showDetallesPicking: _asBool(json['show_detalles_picking']),
      showDetallesPack: _asBool(json['show_detalles_pack']),
      showNextLocationsInDetails: _asBool(json['show_next_locations_in_details']),
      showNextLocationsInDetailsPack:
          _asBool(json['show_next_locations_in_details_pack']),
      showOwnerField: _asBool(json['show_owner_field']),
      countQuantityInventory: _asBool(json['count_quantity_inventory']),
      updateItemInventory: _asBool(json['update_item_inventory']),
      updateLocationInventory: _asBool(json['update_location_inventory']),
      showPhotoTemperature: _asBool(json['show_photo_temperature']),
      locationManualInventory: _asBool(json['location_manual_inventory']),
      manualProductSelectionInventory:
          _asBool(json['manual_product_selection_inventory']),
      manualProductSelectionTransfer:
          _asBool(json['manual_product_selection_transfer']),
      allowPriorExpirationDate: _asBool(json['allow_prior_expiration_date']),
      manageExpirationDateWithoutLot:
          _asBool(json['manage_expiration_date_without_lot']),
      showButtonValidateClusterPicking:
          _asBool(json['show_button_validate_cluster_picking']),
      allowValidateMultiple: _asBool(json['allow_validate_multiple']),
      hideValidateItemExpedition:
          _asBool(json['hide_validate_item_expedition']),
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
      'hide_validate_expedition': hideValidateExpedition,
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
      "show_button_validate_cluster_picking": showButtonValidateClusterPicking,
      "allow_validate_multiple": allowValidateMultiple,
      "hide_validate_item_expedition": hideValidateItemExpedition,
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
