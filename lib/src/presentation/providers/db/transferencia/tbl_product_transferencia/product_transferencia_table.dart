class ProductTransferenciaTable {
  static const String tableName = 'tblproduct_transferencia';

  // static const String columnId = 'id';
  static const String columnIdMove = 'id_move';
  static const String columnProductId = 'product_id';
  static const String columnIdTransferencia = 'id_transferencia';
  static const String columnProductName = 'product_name';
  static const String columnProductCode = 'product_code';
  static const String columnProductBarcode = 'product_barcode';
  static const String columnProductTracking = 'product_tracking';
  static const String columnFechaVencimiento = 'fecha_vencimiento';
  static const String columnDiasVencimiento = 'dias_vencimiento';
  static const String columnQuantityOrdered = 'quantity_ordered';
  static const String columnQuantityToReceive = 'quantity_to_receive';
  static const String columnQuantityDone = 'quantity_done';
  static const String columnUom = 'uom';
  static const String columnLocationDestId = 'location_dest_id';
  static const String columnLocationDestName = 'location_dest_name';
  static const String columnLocationDestBarcode = 'location_dest_barcode';

  static const String columnLocationId = 'location_id';
  static const String columnLocationName = 'location_name';
  static const String columnLocationBarcode = 'location_barcode';
  static const String columnWeight = 'weight';

//info operaciones
  static const String columnIsSelected = 'is_selected';
  static const String columnIsSeparate = 'is_separate';
  static const String columnIsProductSplit = 'is_product_split';
  static const String columnObservation = 'observation';

  static const String columnLoteId = 'lot_id';
  static const String columnLotName = 'lot_name';
  static const String columnLoteDate = 'lote_date';

  static const String columnIsLocationIsOk = 'is_location_is_ok';
  static const String columnProductIsOk = 'product_is_ok';
  static const String columnIsQuantityIsOk = 'is_quantity_is_ok';
  static const String columnLocationDestIsOk = 'location_dest_is_ok';

  static const String columnDateStart = 'date_start';
  static const String columnDateEnd = 'date_end';
  static const String columnTime = 'time';

  static const String columnIsDoneItem = 'is_done_item';
  static const String columnDateTransaction = 'date_transaction';

  static const String columnCantidadFaltante = 'cantidad_faltante';
  static const String columnType = 'type';
  static const String columnManejaSegundaUnidad = 'maneja_segunda_unidad';
  static const String columnUomSegundaUnidad = 'uom_segunda_unidad';
  static const String columnQuantitySegundaUnidad = 'quantity_segunda_unidad';

//Meotdo para crar la tabla
  static String createTable() {
    return '''
    CREATE TABLE $tableName (
      $columnIdMove INTEGER PRIMARY KEY,
      $columnProductId TEXT,
      $columnIdTransferencia INTEGER,
      $columnProductName TEXT,
      $columnProductCode TEXT,
      $columnProductBarcode TEXT,
      $columnProductTracking TEXT,
      $columnFechaVencimiento TEXT,
      $columnDiasVencimiento INTEGER,
      $columnQuantityOrdered REAL,
      $columnQuantityToReceive REAL,
      $columnQuantityDone REAL,
      $columnUom TEXT,
      $columnLocationDestId INTEGER,
      $columnLocationDestName TEXT,
      $columnLocationDestBarcode TEXT,
      $columnLocationBarcode TEXT,
      $columnLocationId INTEGER,
      $columnLocationName TEXT,
      $columnWeight REAL,
      $columnIsSelected INTEGER,
      $columnIsSeparate INTEGER,
      $columnIsProductSplit INTEGER,
      $columnObservation TEXT,
      $columnLoteId INTEGER,
      $columnLotName TEXT,
      $columnIsLocationIsOk INTEGER,
      $columnProductIsOk INTEGER,
      $columnIsQuantityIsOk INTEGER,
      $columnLocationDestIsOk INTEGER,
      $columnLoteDate TEXT,
      $columnDateStart TEXT,
      $columnDateEnd TEXT,
      $columnTime INTEGER,
      $columnIsDoneItem INTEGER,  
      $columnDateTransaction TEXT,
      $columnCantidadFaltante REAL,
      $columnType TEXT,
      $columnManejaSegundaUnidad INTEGER,
      $columnUomSegundaUnidad TEXT,
      $columnQuantitySegundaUnidad REAL,
      FOREIGN KEY ($columnIdTransferencia) REFERENCES tbl_entradas_recepcion ($columnIdMove)

    )
  ''';
  }
}
