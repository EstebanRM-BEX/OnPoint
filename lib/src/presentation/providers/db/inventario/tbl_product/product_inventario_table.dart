class ProductInventarioTable {
  static const String tableName = 'tblproductos_inventario';

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
  static const String columnCategory = 'category';
  static const String columnManejoPropietario = 'manejo_propietario';
  static const String columnPropietario = 'propietario';
  static const String columnIdPropietario = 'id_propietario';

  // ✅ NUEVO: Columna para estrategia de sincronización
  static const String columnIsSynced = 'is_synced';
  static const String columnManejaSegundaUnidad = 'maneja_segunda_unidad';
  static const String columnUomSegundaUnidad = 'uom_segunda_unidad';

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
        $columnCategory TEXT,
        $columnVolumeUomName TEXT,
        $columnPropietario TEXT,
        $columnIdPropietario INTEGER,
        $columnManejoPropietario INTEGER DEFAULT 0,
        $columnIsSynced INTEGER DEFAULT 0,
        $columnManejaSegundaUnidad INTEGER DEFAULT 0,
        $columnUomSegundaUnidad TEXT DEFAULT ''
      );

      -- ✅ ÍNDICES DE RENDIMIENTO
      
      -- Índice Único para Upsert (Reemplaza duplicados de stock)
      CREATE UNIQUE INDEX idx_unique_inventory_stock ON $tableName ($columnProductId, $columnLotId, $columnLocationId);

      -- Índices de Búsqueda Rápida
      CREATE INDEX idx_inv_barcode ON $tableName ($columnBarcode);
      CREATE INDEX idx_inv_product_id ON $tableName ($columnProductId);
    ''';
  }
}
