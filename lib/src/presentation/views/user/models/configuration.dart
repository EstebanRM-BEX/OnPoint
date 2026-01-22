// To parse this JSON data, do
//
//     final configurations = configurationsFromMap(jsonString);

import 'dart:convert';

Configurations configurationsFromMap(String str) =>
    Configurations.fromMap(json.decode(str));

String configurationsToMap(Configurations data) => json.encode(data.toMap());

class Configurations {
  String? jsonrpc;
  dynamic id;
  ConfigurationsResult? result;

  Configurations({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory Configurations.fromMap(Map<String, dynamic> json) => Configurations(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null
            ? null
            : ConfigurationsResult.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
      };
}

class ConfigurationsResult {
  int? code;
  String? msg;
  DataConfig? result;

  ConfigurationsResult({
    this.code,
    this.result,
    this.msg,
  });

  factory ConfigurationsResult.fromMap(Map<String, dynamic> json) =>
      ConfigurationsResult(
        code: json["code"],
        msg: json["msg"],
        result:
            json["result"] == null ? null : DataConfig.fromMap(json["result"]),
      );

  Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "result": result?.toMap(),
      };
}

class DataConfig {
  String? name;
  int? id;
  String? lastName;
  String? email;
  String? rol;
  String? muelleOption;
  List<AllowedWarehouse>? allowedWarehouses;
  bool? locationPickingManual;
  bool? manualProductSelection;
  bool? manualQuantity;
  bool? manualSpringSelection;
  bool? showDetallesPicking;
  bool? showNextLocationsInDetails;
  bool? locationPackManual;
  bool? showDetallesPack;
  bool? showNextLocationsInDetailsPack;
  bool? manualProductSelectionPack;
  bool? manualQuantityPack;
  bool? manualSpringSelectionPack;
  bool? scanProduct;
  bool? allowMoveExcess;
  bool? hideExpectedQty;
  bool? manualProductReading;
  bool? manualSourceLocation;
  bool? showOwnerField;
  bool? manualProductSelectionTransfer;
  bool? manualSourceLocationTransfer;
  bool? manualDestLocationTransfer;
  bool? manualQuantityTransfer;
  bool? countQuantityInventory;
  bool? allowMoveExcessProduction;


  bool? hideValidateTransfer;
  bool? hideValidateReception;
  bool? hideValidatePacking;
  bool? hideValidatePicking;
  bool? accessProductionModule;

  bool? updateItemInventory;

  bool? scanDestinationLocationReception;
  bool? updateLocationInventory;
  bool? showPhotoTemperature;

  String? returnsLocationDestOption;
  // location_manual_inventory
  bool? locationManualInventory;
  // manual_product_selection_inventory
  bool? manualProductSelectionInventory;





  DataConfig({
    this.name,
    this.id,
    this.lastName,
    this.email,
    this.rol,
    this.muelleOption,
    this.allowedWarehouses,
    this.locationPickingManual,
    this.manualProductSelection,
    this.manualQuantity,
    this.manualSpringSelection,
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
    this.scanDestinationLocationReception,
    this.hideValidateTransfer,
    this.hideValidateReception,
    this.updateItemInventory,
    this.updateLocationInventory,
    this.hideValidatePacking,
    this.hideValidatePicking,
    this.showPhotoTemperature,
    this.returnsLocationDestOption,
    this.locationManualInventory,
    this.manualProductSelectionInventory,
    this.allowMoveExcessProduction,
    //accessProductionModule
    this.accessProductionModule,
  });

  factory DataConfig.fromMap(Map<String, dynamic> json) => DataConfig(
        name: json["name"],
        id: json["id"],
        lastName: json["last_name"],
        email: json["email"],
        rol: json["rol"],
        muelleOption: json["muelle_option"],
        allowedWarehouses: json["allowed_warehouses"] == null
            ? []
            : List<AllowedWarehouse>.from(json["allowed_warehouses"]!
                .map((x) => AllowedWarehouse.fromMap(x))),
        locationPickingManual: json["location_picking_manual"],
        manualProductSelection: json["manual_product_selection"],
        manualQuantity: json["manual_quantity"],
        manualSpringSelection: json["manual_spring_selection"],
        showDetallesPicking: json["show_detalles_picking"],
        showNextLocationsInDetails: json["show_next_locations_in_details"],
        locationPackManual: json["location_pack_manual"],
        showDetallesPack: json["show_detalles_pack"],
        showNextLocationsInDetailsPack:
            json["show_next_locations_in_details_pack"],
        manualProductSelectionPack: json["manual_product_selection_pack"],
        manualQuantityPack: json["manual_quantity_pack"],
        manualSpringSelectionPack: json["manual_spring_selection_pack"],
        scanProduct: json["scan_product"],
        allowMoveExcess: json["allow_move_excess"],
        hideExpectedQty: json["hide_expected_qty"],
        manualProductReading: json["manual_product_reading"],
        manualSourceLocation: json["manual_source_location"],
        showOwnerField: json["show_owner_field"],
        manualProductSelectionTransfer:
            json["manual_product_selection_transfer"],
        manualSourceLocationTransfer: json["manual_source_location_transfer"],
        manualDestLocationTransfer: json["manual_dest_location_transfer"],
        manualQuantityTransfer: json["manual_quantity_transfer"],
        countQuantityInventory: json["count_quantity_inventory"],
        scanDestinationLocationReception:
            json["scan_destination_location_reception"],
        hideValidateTransfer: json["hide_validate_transfer"],
        hideValidateReception: json["hide_validate_reception"],
        updateItemInventory: json["update_item_inventory"],
        updateLocationInventory: json["update_location_inventory"],
        hideValidatePacking: json["hide_validate_packing"],
        hideValidatePicking: json["hide_validate_picking"],
        showPhotoTemperature: json["show_photo_temperature"],
        returnsLocationDestOption: json["returns_location_dest_option"],
        locationManualInventory: json["location_manual_inventory"],
        manualProductSelectionInventory: json["manual_product_selection_inventory"],
        accessProductionModule: json["access_production_module"],
        allowMoveExcessProduction: json["allow_move_excess_production"],
      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "id": id,
        "last_name": lastName,
        "email": email,
        "rol": rol,
        "muelle_option": muelleOption,
        "allowed_warehouses": allowedWarehouses == null
            ? []
            : List<dynamic>.from(allowedWarehouses!.map((x) => x.toMap())),
        "location_picking_manual": locationPickingManual,
        "manual_product_selection": manualProductSelection,
        "manual_quantity": manualQuantity,
        "manual_spring_selection": manualSpringSelection,
        "show_detalles_picking": showDetallesPicking,
        "show_next_locations_in_details": showNextLocationsInDetails,
        "location_pack_manual": locationPackManual,
        "show_detalles_pack": showDetallesPack,
        "show_next_locations_in_details_pack": showNextLocationsInDetailsPack,
        "manual_product_selection_pack": manualProductSelectionPack,
        "manual_quantity_pack": manualQuantityPack,
        "manual_spring_selection_pack": manualSpringSelectionPack,
        "scan_product": scanProduct,
        "allow_move_excess": allowMoveExcess,
        "hide_expected_qty": hideExpectedQty,
        "manual_product_reading": manualProductReading,
        "manual_source_location": manualSourceLocation,
        "show_owner_field": showOwnerField,
        "manual_product_selection_transfer": manualProductSelectionTransfer,
        "manual_source_location_transfer": manualSourceLocationTransfer,
        "manual_dest_location_transfer": manualDestLocationTransfer,
        "manual_quantity_transfer": manualQuantityTransfer,
        "count_quantity_inventory": countQuantityInventory,
        "scan_destination_location_reception":
            scanDestinationLocationReception,
        "hide_validate_transfer": hideValidateTransfer,
        "hide_validate_reception": hideValidateReception,
        "update_item_inventory": updateItemInventory,
        "update_location_inventory": updateLocationInventory,
        "hide_validate_packing": hideValidatePacking,
        "hide_validate_picking": hideValidatePicking,
        "show_photo_temperature": showPhotoTemperature,
        "returns_location_dest_option": returnsLocationDestOption,  
        "location_manual_inventory": locationManualInventory,
        "manual_product_selection_inventory": manualProductSelectionInventory,
        "access_production_module": accessProductionModule,
        "allow_move_excess_production": allowMoveExcessProduction,
      };
}




class AllowedWarehouse {
    int? id;
    String? name;

    AllowedWarehouse({
        this.id,
        this.name,
    });

    factory AllowedWarehouse.fromMap(Map<String, dynamic> json) => AllowedWarehouse(
        id: json["id"],
        name: json["name"],
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
    };
}
