class PickingPickTable {
  static const String tableName = 'tbl_picking_pick';

  // Columnas de la tabla
  static const String columnId = 'id';
  static const String columnName = 'name';
  //observacion
  static const String columnObservacion = 'observacion';
  static const String columnFechaCreacion = 'fecha_creacion';
  static const String columnLocationId = 'location_id';
  static const String columnLocationName = 'location_name';
  static const String columnLocationBarcode = 'location_barcode';
  static const String columnLocationDestId = 'location_dest_id';
  static const String columnLocationDestName = 'location_dest_name';
  static const String columnLocationDestBarcode = 'location_dest_barcode';
  static const String columnProveedor = 'proveedor';
  static const String columnNumeroTransferencia = 'numero_transferencia';
  static const String columnPesoTotal = 'peso_total';
  static const String columnNumeroLineas = 'numero_lineas';
  static const String columnNumeroItems = 'numero_items';
  static const String columnState = 'state';
  static const String columnOrigin = 'origin';
  static const String columnPriority = 'priority';
  static const String columnWarehouseId = 'warehouse_id';
  static const String columnWarehouseName = 'warehouse_name';
  static const String columnResponsableId = 'responsable_id';
  static const String columnResponsable = 'responsable';
  static const String columnPickingType = 'picking_type';
  static const String columnStartTimeTransfer = 'start_time_transfer';
  static const String columnEndTimeTransfer = 'end_time_transfer';
  static const String columnBackorderId = 'backorder_id';
  static const String columnBackorderName = 'backorder_name';
  static const String columnShowCheckAvailability = 'show_check_availability';
  static const String columnIsSeparate = 'is_separate';
  static const String columnIsSelected = 'is_selected';
  static const String columnZonaEntrega = 'zona_entrega';
  static const String columnMuelle = 'muelle';
  static const String columnBarcodeMuelle = 'barcode_muelle';
  static const String columnMuelleId = 'muelle_id';
  static const String columnIdMuellePadre = 'id_muelle_padre';
  static const String columnIndexList = 'index_list';

  static const String columnIsSendOddo = 'is_send_oddo';
  static const String columnIsSendOddoDate = 'is_send_oddo_date';
  static const String columnOrderBy = 'order_by';
  static const String columnOrderPicking = 'order_picking';

  static const String columnTypePick = 'type_pick';


  //datos de picking de componentes
  static const String productoFinalNombre = 'producto_final_nombre';
  //producto final referencia
  static const String productoFinalReferencia = 'producto_final_referencia'; 

  //create_backorder
  static const String createBackorder = 'create_backorder';


  // Método para crear la tabla
  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT,
        $columnObservacion TEXT,
        $columnFechaCreacion TEXT,
        $columnLocationId INTEGER,
        $columnLocationName TEXT,
        $columnLocationBarcode TEXT,
        $columnLocationDestId INTEGER,
        $columnLocationDestName TEXT,
        $columnLocationDestBarcode TEXT,
        $columnProveedor TEXT,
        $columnNumeroTransferencia TEXT,
        $columnPesoTotal INTEGER,
        $columnNumeroLineas TEXT,
        $columnNumeroItems TEXT,
        $columnState TEXT,
        $columnOrigin TEXT,
        $columnPriority TEXT,
        $columnWarehouseId INTEGER,
        $columnWarehouseName TEXT,
        $columnResponsableId INTEGER,
        $columnResponsable TEXT,
        $columnPickingType TEXT,
        $columnStartTimeTransfer TEXT,
        $columnEndTimeTransfer TEXT,
        $columnBackorderId INTEGER,
        $columnBackorderName TEXT,
        $columnShowCheckAvailability INTEGER,
        $columnIsSeparate INTEGER,
        $columnIsSelected INTEGER,
        $columnZonaEntrega TEXT,
        $columnMuelle TEXT,
        $columnBarcodeMuelle TEXT,
        $columnMuelleId INTEGER,
        $columnIdMuellePadre INTEGER,
        $columnIndexList INTEGER,
        $columnIsSendOddo INTEGER,
        $columnIsSendOddoDate VARCHAR(255),
        $columnOrderBy TEXT,
        $columnTypePick TEXT,
        $productoFinalNombre TEXT,
        $productoFinalReferencia TEXT,
        $createBackorder TEXT,
        $columnOrderPicking TEXT

      )
    ''';
  }
}
