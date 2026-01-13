class ProductDevolucionTable {
  static const String tableName = 'tblproductos_devolucion';

  // Columnas de la tabla
  static const String columnId = 'id';
  static const String columnProductId = 'product_id';
  static const String columnProductName = 'name';
  static const String columnBarcode = 'barcode';
  static const String columnProductracking = 'tracking';
  static const String columnLotId = 'lot_id';
  static const String columnLotName = 'lot_name';
  static const String columnExpirationDate = 'expiration_time';
  static const String columnProductCode = 'code';
  static const String columnWeight = 'weight';
  static const String columnWeightUomName = 'weight_uom_name';
  static const String columnVolume = 'volume';
  static const String columnVolumeUomName = 'volume_uom_name';
  static const String columnUom = 'uom';
  static const String columnLocationId = 'location_id';
  static const String columnLocationName = 'location_name';
  static const String columnQuantity = 'quantity';
  static const String columnUseExpirationDate = 'use_expiration_date';
  
  // ✅ NUEVO: Columna de sincronización
  static const String columnIsSynced = 'is_synced';

  static String createTable() {
    return '''
       CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnProductCode TEXT,
        $columnProductId INTEGER,
        $columnProductName TEXT,
        $columnBarcode TEXT,
        $columnProductracking TEXT,
        $columnLotId INTEGER,
        $columnLotName TEXT,
        $columnExpirationDate TEXT,
        $columnWeight REAL,
        $columnWeightUomName TEXT,
        $columnVolume REAL,
        $columnUom TEXT,
        $columnLocationId INTEGER,
        $columnLocationName TEXT,
        $columnQuantity REAL,
        $columnUseExpirationDate INTEGER,
        $columnVolumeUomName TEXT,
        $columnIsSynced INTEGER DEFAULT 0
      );

      -- ✅ ÍNDICES DE RENDIMIENTO
      
      -- Índice Único para Upsert (Reemplaza duplicados Producto + Lote)
      CREATE UNIQUE INDEX idx_unique_devolucion ON $tableName ($columnProductId, $columnLotId);

      -- Índice para buscar rápido por código de barras
      CREATE INDEX idx_dev_barcode ON $tableName ($columnBarcode);
    ''';
  }
}