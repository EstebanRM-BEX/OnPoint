class PickProductsTable {
  static const String tableName = 'tbl_pick_products';

  // Columnas
  static const String columnRowId = 'row_id';
  static const String columnId = 'id';
  static const String columnIdProduct = 'id_product';
  static const String columnBatchId = 'batch_id';
  static const String columnExpireDate = 'expire_date';
  static const String columnProductId = 'product_id';
  static const String columnPickingId = 'picking_id';
  static const String columnLote = 'lote';
  static const String columnLoteId = 'lote_id';
  static const String columnIdMove = 'id_move';
  static const String columnLocationId = 'location_id';
  static const String columnLocationDestId = 'location_dest_id';
  static const String columnIdLocationDest = 'id_location_dest';
  static const String columnQuantity = 'quantity';
  static const String columnBarcode = 'barcode';
  static const String columnRimovalPriority = 'rimoval_priority';
  static const String columnBarcodeLocationDest = 'barcode_location_dest';
  static const String columnBarcodeLocation = 'barcode_location';
  static const String columnQuantitySeparate = 'quantity_separate';
  static const String columnIsSelected = 'is_selected';
  static const String columnIsSeparate = 'is_separate';
  static const String columnIsPending = 'is_pending';
  static const String columnOrderProduct = 'order_product';
  static const String columnTimeSeparate = 'time_separate';
  static const String columnTimeSeparateStart = 'time_separate_start';
  static const String columnTimeSeparateEnd = 'time_separate_end';
  static const String columnOrigin = 'origin';
  static const String columnObservation = 'observation';
  static const String columnUnidades = 'unidades';
  static const String columnWeight = 'weight';
  static const String columnIsMuelle = 'is_muelle';
  static const String columnMuelleId = 'muelle_id';
  static const String columnIsLocationIsOk = 'is_location_is_ok';
  static const String columnProductIsOk = 'product_is_ok';
  static const String columnIsQuantityIsOk = 'is_quantity_is_ok';
  static const String columnLocationDestIsOk = 'location_dest_is_ok';
  static const String columnFechaTransaccion = 'fecha_transaccion';
  static const String columnIsSendOdoo = 'is_send_odoo';
  static const String columnIsSendOdooDate = 'is_send_odoo_date';
  //product_code
  static const String columnProductCode = 'product_code';
  //columnTypePick
  static const String columnTypePick = 'type_pick';

  //productTracking 
  static const String columnProductTracking = 'product_tracking';

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnRowId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnId INTEGER,
        $columnIdProduct INTEGER,
        $columnBatchId INTEGER,
        $columnExpireDate VARCHAR(255),
        $columnProductId INTEGER,
        $columnPickingId TEXT,
        $columnLote TEXT,
        $columnLoteId INTEGER,
        $columnIdMove INTEGER,
        $columnLocationId TEXT,
        $columnLocationDestId TEXT,
        $columnIdLocationDest INTEGER,
        $columnQuantity REAL,
        $columnBarcode TEXT,
        $columnRimovalPriority INTEGER,
        $columnBarcodeLocationDest TEXT,
        $columnBarcodeLocation TEXT,
        $columnQuantitySeparate REAL,
        $columnIsSelected INTEGER,
        $columnIsSeparate INTEGER,
        $columnIsPending INTEGER,
        $columnOrderProduct INTEGER,
        $columnTimeSeparate DECIMAL(10,2),
        $columnTimeSeparateStart VARCHAR(255),
        $columnTimeSeparateEnd VARCHAR(255),
        $columnOrigin VARCHAR(255),
        $columnObservation TEXT,
        $columnUnidades TEXT,
        $columnWeight REAL,
        $columnIsMuelle INTEGER,
        $columnMuelleId INTEGER,
        $columnIsLocationIsOk INTEGER,
        $columnProductIsOk INTEGER,
        $columnIsQuantityIsOk INTEGER,
        $columnLocationDestIsOk INTEGER,
        $columnFechaTransaccion VARCHAR(255),
        $columnIsSendOdoo INTEGER,
        $columnIsSendOdooDate VARCHAR(255),
        $columnProductCode TEXT,
        $columnProductTracking TEXT,
        $columnTypePick TEXT,
        UNIQUE($columnIdProduct, $columnBatchId, $columnIdMove),
        FOREIGN KEY ($columnBatchId) REFERENCES tbl_picking_pick (id)
      )
    ''';
  }
}
