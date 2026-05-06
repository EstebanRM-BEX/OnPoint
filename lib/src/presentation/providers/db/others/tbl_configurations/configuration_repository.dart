// configurations_repository.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/user/data/models/user_configuration_model.dart';
import 'package:wms_app/features/user/domain/entities/user_configuration.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_configurations/configuration_table.dart';

class ConfigurationsRepository {
  static const int _batchSize = 500;

  /// --------------------------------------------------------------------------
  /// OPTIMIZED METHOD: syncConfigurations (Mark & Sweep)
  /// --------------------------------------------------------------------------
  /// Useful if you download a list of configurations (e.g. for multiple users).
  Future<void> syncConfigurations(List<UserConfiguration> configList) async {
    if (configList.isEmpty) return;

    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      await db.transaction((txn) async {
        // STEP 1: MARK (Reset flag)
        await txn.rawUpdate(
            'UPDATE ${ConfigurationsTable.tableName} SET ${ConfigurationsTable.columnIsSynced} = 0');

        // STEP 2: UPSERT BY BATCH
        for (var i = 0; i < configList.length; i += _batchSize) {
          final end = (i + _batchSize < configList.length)
              ? i + _batchSize
              : configList.length;
          final batchList = configList.sublist(i, end);
          final batch = txn.batch();

          for (var config in batchList) {
            // Note: Assuming 'id' in the model corresponds to the userId for the PK
            // If not, ensure you pass the correct ID.
            // Your original code passed 'userId' separately.
            // Here we assume config.result.result.id is the key, or we need a way to map it.
            // Based on getConfiguration, it seems 'id' is stored in the DB.

            final data = _mapToDB(config);
            // Ensure ID is set if it comes from the object
            if (config.result?.result?.id != null) {
              data[ConfigurationsTable.columnId] = config.result?.result?.id;
            }

            batch.insert(
              ConfigurationsTable.tableName,
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        }

        // STEP 3: SWEEP (Delete obsolete)
        int deleted = await txn.delete(
          ConfigurationsTable.tableName,
          where: '${ConfigurationsTable.columnIsSynced} = ?',
          whereArgs: [0],
        );

        debugPrint(
            "⚙️ Config Sync: Processed ${configList.length} | Deleted Obsolete: $deleted");
      });
    } catch (e, s) {
      debugPrint("❌ Error in syncConfigurations: $e => $s");
    }
  }

  /// --------------------------------------------------------------------------
  /// SINGLE INSERT (Legacy Support / Single User Login)
  /// --------------------------------------------------------------------------
  Future<void> insertConfiguration(
      UserConfiguration configuration, int userId) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      Map<String, dynamic> configurationData = _mapToDB(configuration);
      // Explicitly set the ID passed as argument
      configurationData[ConfigurationsTable.columnId] = userId;

      await db.insert(
        ConfigurationsTable.tableName,
        configurationData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint("✅ Configuration inserted/updated successfully.");
    } catch (e, s) {
      debugPrint("❌ Error inserting configuration: $e => $s");
    }
  }

  /// --------------------------------------------------------------------------
  /// READ METHOD
  /// --------------------------------------------------------------------------
  Future<UserConfigurationModel?> getConfiguration(int userId) async {
    try {
      Database db = await DataBaseSqlite().getDatabaseInstance();

      final List<Map<String, dynamic>> maps = await db.query(
        ConfigurationsTable.tableName,
        where: '${ConfigurationsTable.columnId} = ?',
        whereArgs: [userId],
      );

      if (maps.isNotEmpty) {
        // ✅ Usar _mapFromDB para convertir correctamente los datos de SQLite
        return _mapFromDB(maps.first);
      } else {
        return null;
      }
    } catch (e, s) {
      debugPrint("❌ Error fetching configuration: $e => $s");
      return null;
    }
  }

  /// --------------------------------------------------------------------------
  /// PRIVATE HELPERS (Mapping)
  /// --------------------------------------------------------------------------

  // Maps Object -> DB Map
  Map<String, dynamic> _mapToDB(UserConfiguration config) {
    final res = config.result?.result;
    return {
      // Note: ID is handled by the caller typically, but can be here too
      // ConfigurationsTable.columnId: res?.id,
      ConfigurationsTable.columnName: res?.name,
      ConfigurationsTable.columnLastName: res?.lastName,
      ConfigurationsTable.columnEmail: res?.email,
      ConfigurationsTable.columnRol: res?.rol,
      ConfigurationsTable.columnMuelleOption: res?.muelleOption,
      ConfigurationsTable.columnLocationPickingManual:
          _boolToInt(res?.locationPickingManual),
      ConfigurationsTable.columnManualProductSelection:
          _boolToInt(res?.manualProductSelection),
      ConfigurationsTable.columnManualQuantity: _boolToInt(res?.manualQuantity),
      ConfigurationsTable.columnManualSpringSelection:
          _boolToInt(res?.manualSpringSelection),
      ConfigurationsTable.columnShowDetallesPicking:
          _boolToInt(res?.showDetallesPicking),
      ConfigurationsTable.columnShowNextLocationsInDetails:
          _boolToInt(res?.showNextLocationsInDetails),
      ConfigurationsTable.columnLocationPackManual:
          _boolToInt(res?.locationPackManual),
      ConfigurationsTable.columnShowDetallesPack:
          _boolToInt(res?.showDetallesPack),
      ConfigurationsTable.columnShowNextLocationsInDetailsPack:
          _boolToInt(res?.showNextLocationsInDetailsPack),
      ConfigurationsTable.columnManualProductSelectionPack:
          _boolToInt(res?.manualProductSelectionPack),
      ConfigurationsTable.columnManualQuantityPack:
          _boolToInt(res?.manualQuantityPack),
      ConfigurationsTable.columnManualSpringSelectionPack:
          _boolToInt(res?.manualSpringSelectionPack),
      ConfigurationsTable.columnScanProduct: _boolToInt(res?.scanProduct),
      ConfigurationsTable.columnAllowMoveExcess:
          _boolToInt(res?.allowMoveExcess),
      ConfigurationsTable.columnHideExpectedQty:
          _boolToInt(res?.hideExpectedQty),
      ConfigurationsTable.columnManualProductReading:
          _boolToInt(res?.manualProductReading),
      ConfigurationsTable.columnManualSourceLocation:
          _boolToInt(res?.manualSourceLocation),
      ConfigurationsTable.columnShowOwnerField: _boolToInt(res?.showOwnerField),
      ConfigurationsTable.columnManualProductSelectionTransfer:
          _boolToInt(res?.manualProductSelectionTransfer),
      ConfigurationsTable.columnManualSourceLocationTransfer:
          _boolToInt(res?.manualSourceLocationTransfer),
      ConfigurationsTable.columnManualDestLocationTransfer:
          _boolToInt(res?.manualDestLocationTransfer),
      ConfigurationsTable.columnManualQuantityTransfer:
          _boolToInt(res?.manualQuantityTransfer),
      ConfigurationsTable.columnScanDestinationLocationReception:
          _boolToInt(res?.scanDestinationLocationReception),
      ConfigurationsTable.columnHideValidateTransfer:
          _boolToInt(res?.hideValidateTransfer),
      ConfigurationsTable.columnHideValidateReception:
          _boolToInt(res?.hideValidateReception),
      ConfigurationsTable.columnCountQuantityInventory:
          _boolToInt(res?.countQuantityInventory),
      ConfigurationsTable.columnUpdateItemInventory:
          _boolToInt(res?.updateItemInventory),
      ConfigurationsTable.columnUpdateLocationInventory:
          _boolToInt(res?.updateLocationInventory),
      ConfigurationsTable.columnHideValidatePacking:
          _boolToInt(res?.hideValidatePacking),
      ConfigurationsTable.columnHideValidatePicking:
          _boolToInt(res?.hideValidatePicking),
      ConfigurationsTable.columnShowPhotoTemperature:
          _boolToInt(res?.showPhotoTemperature),
      ConfigurationsTable.columnAccessProductionModule:
          _boolToInt(res?.accessProductionModule),
      ConfigurationsTable.columnLocationManualInventory:
          _boolToInt(res?.locationManualInventory),
      ConfigurationsTable.columnManualProductSelectionInventory:
          _boolToInt(res?.manualProductSelectionInventory),
      ConfigurationsTable.columnAllowMoveExcessProduction:
          _boolToInt(res?.allowMoveExcessProduction),
      ConfigurationsTable.columnReturnsLocationDestOption:
          res?.returnsLocationDestOption ?? 'dynamic',
      ConfigurationsTable.columnAllowPriorExpirationDate:
          _boolToInt(res?.allowPriorExpirationDate),
      ConfigurationsTable.columnManageExpirationDateWithoutLot:
          _boolToInt(res?.manageExpirationDateWithoutLot),
      // ✅ Mark as synced
      ConfigurationsTable.columnIsSynced: 1,
    };
  }

  // Maps DB Map -> Object
  UserConfigurationModel _mapFromDB(Map<String, dynamic> map) {
    return UserConfigurationModel(
      result: UserConfigurationResultModel(
        code: 200,
        result: UserProfileModel(
          id: map[ConfigurationsTable.columnId],
          name: map[ConfigurationsTable.columnName],
          lastName: map[ConfigurationsTable.columnLastName],
          email: map[ConfigurationsTable.columnEmail],
          rol: map[ConfigurationsTable.columnRol],
          muelleOption: map[ConfigurationsTable.columnMuelleOption],
          locationPickingManual:
              _intToBool(map[ConfigurationsTable.columnLocationPickingManual]),
          manualProductSelection:
              _intToBool(map[ConfigurationsTable.columnManualProductSelection]),
          manualQuantity:
              _intToBool(map[ConfigurationsTable.columnManualQuantity]),
          manualSpringSelection:
              _intToBool(map[ConfigurationsTable.columnManualSpringSelection]),
          showDetallesPicking:
              _intToBool(map[ConfigurationsTable.columnShowDetallesPicking]),
          showNextLocationsInDetails: _intToBool(
              map[ConfigurationsTable.columnShowNextLocationsInDetails]),
          locationPackManual:
              _intToBool(map[ConfigurationsTable.columnLocationPackManual]),
          showDetallesPack:
              _intToBool(map[ConfigurationsTable.columnShowDetallesPack]),
          showNextLocationsInDetailsPack: _intToBool(
              map[ConfigurationsTable.columnShowNextLocationsInDetailsPack]),
          manualProductSelectionPack: _intToBool(
              map[ConfigurationsTable.columnManualProductSelectionPack]),
          manualQuantityPack:
              _intToBool(map[ConfigurationsTable.columnManualQuantityPack]),
          manualSpringSelectionPack: _intToBool(
              map[ConfigurationsTable.columnManualSpringSelectionPack]),
          scanProduct: _intToBool(map[ConfigurationsTable.columnScanProduct]),
          allowMoveExcess:
              _intToBool(map[ConfigurationsTable.columnAllowMoveExcess]),
          hideExpectedQty:
              _intToBool(map[ConfigurationsTable.columnHideExpectedQty]),
          manualProductReading:
              _intToBool(map[ConfigurationsTable.columnManualProductReading]),
          manualSourceLocation:
              _intToBool(map[ConfigurationsTable.columnManualSourceLocation]),
          showOwnerField:
              _intToBool(map[ConfigurationsTable.columnShowOwnerField]),
          manualProductSelectionTransfer: _intToBool(
              map[ConfigurationsTable.columnManualProductSelectionTransfer]),
          manualSourceLocationTransfer: _intToBool(
              map[ConfigurationsTable.columnManualSourceLocationTransfer]),
          manualDestLocationTransfer: _intToBool(
              map[ConfigurationsTable.columnManualDestLocationTransfer]),
          manualQuantityTransfer:
              _intToBool(map[ConfigurationsTable.columnManualQuantityTransfer]),
          scanDestinationLocationReception: _intToBool(
              map[ConfigurationsTable.columnScanDestinationLocationReception]),
          hideValidateTransfer:
              _intToBool(map[ConfigurationsTable.columnHideValidateTransfer]),
          hideValidateReception:
              _intToBool(map[ConfigurationsTable.columnHideValidateReception]),
          countQuantityInventory:
              _intToBool(map[ConfigurationsTable.columnCountQuantityInventory]),
          updateItemInventory:
              _intToBool(map[ConfigurationsTable.columnUpdateItemInventory]),
          updateLocationInventory: _intToBool(
              map[ConfigurationsTable.columnUpdateLocationInventory]),
          hideValidatePacking:
              _intToBool(map[ConfigurationsTable.columnHideValidatePacking]),
          hideValidatePicking:
              _intToBool(map[ConfigurationsTable.columnHideValidatePicking]),
          showPhotoTemperature:
              _intToBool(map[ConfigurationsTable.columnShowPhotoTemperature]),
          accessProductionModule:
              _intToBool(map[ConfigurationsTable.columnAccessProductionModule]),
          locationManualInventory: _intToBool(
              map[ConfigurationsTable.columnLocationManualInventory]),
          manualProductSelectionInventory: _intToBool(
              map[ConfigurationsTable.columnManualProductSelectionInventory]),
          // allow_move_excess_production
          allowMoveExcessProduction: _intToBool(
              map[ConfigurationsTable.columnAllowMoveExcessProduction]),
          returnsLocationDestOption:
              map[ConfigurationsTable.columnReturnsLocationDestOption] ??
                  'dynamic',
          allowPriorExpirationDate: _intToBool(
              map[ConfigurationsTable.columnAllowPriorExpirationDate]),
          manageExpirationDateWithoutLot: _intToBool(
              map[ConfigurationsTable.columnManageExpirationDateWithoutLot]),
        ),
      ),
    );
  }

  int _boolToInt(bool? value) => value == true ? 1 : 0;
  bool _intToBool(int? value) => value == 1;
}
