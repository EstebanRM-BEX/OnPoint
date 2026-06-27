class ProductRecepcionBatchTable {
  static const String tableName = 'product_entrada_batch';

  static const String columnId = 'id';
  static const String columnIdMove = 'id_move';
  static const String columnProductId = 'product_id';
  static const String columnIdRecepcion = 'id_recepcion';
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
  static const String columnQuantitySeparate = 'quantity_separate';

  static const String columnLoteId = 'lot_id';
  static const String columnLotName = 'lot_name';
  static const String columnLoteDate = 'lote_date';

  static const String columnProductIsOk = 'product_is_ok';
  static const String columnIsQuantityIsOk = 'is_quantity_is_ok';
  static const String columnLocationDestIsOk = 'locationdest_is_ok';

  static const String columnDateStart = 'date_start';
  static const String columnDateEnd = 'date_end';
  static const String columnTime = 'time';

  static const String columnIsDoneItem = 'is_done_item';
  static const String columnDateTransaction = 'date_transaction';
  static const String columnCantidadFaltante = 'cantidad_faltante';

  //temperature
  static const String columnManejoTemperature = 'maneja_temperatura';
  static const String columnTemperature = 'temperatura';
  static const String columnImage = 'image';

  //use_expiration_date
  static const String columnUseExpirationDate = 'use_expiration_date';

  // segunda unidad
  static const String columnManejaSegundaUnidad = 'maneja_segunda_unidad';
  static const String columnUomSegundaUnidad = 'uom_segunda_unidad';
  static const String columnQuantitySegundaUnidad = 'quantity_segunda_unidad';

//Meotdo para crar la tabla
  static String createTable() {
    return '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY,
      $columnIdMove INTEGER,
      $columnProductId TEXT,
      $columnIdRecepcion INTEGER,
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
      $columnQuantitySeparate REAL,
      $columnLoteId INTEGER,
      $columnLotName TEXT,
      $columnProductIsOk INTEGER,
      $columnLocationDestIsOk INTEGER,
      $columnIsQuantityIsOk INTEGER,
      $columnLoteDate TEXT,
      $columnDateStart TEXT,
      $columnDateEnd TEXT,
      $columnTime TEXT,
      $columnIsDoneItem INTEGER,  
      $columnDateTransaction TEXT,
      $columnCantidadFaltante INTEGER,
      $columnManejoTemperature INTEGER,
      $columnTemperature INTEGER,
      $columnUseExpirationDate INTEGER,
      $columnImage TEXT,
      $columnManejaSegundaUnidad INTEGER,
      $columnUomSegundaUnidad TEXT,
      $columnQuantitySegundaUnidad REAL,
      FOREIGN KEY ($columnIdRecepcion) REFERENCES tbl_entradas_recepcion_batch ($columnId)

    )
  ''';
  }
}
