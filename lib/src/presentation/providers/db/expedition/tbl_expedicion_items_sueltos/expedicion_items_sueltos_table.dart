class ExpedicionItemsSueltosTable {
  static const String tableName = 'tbl_expedicion_items_sueltos';

  static const String columnId = 'id';
  static const String columnExpeditionId = 'expedition_id';
  static const String columnPackingId = 'packing_id';
  static const String columnProductName = 'product_name';
  static const String columnProductCode = 'product_code';
  static const String columnBarcode = 'barcode';
  static const String columnOrderPacking = 'order_packing';
  static const String columnQuantity = 'quantity';
  static const String columnUom = 'uom';
  static const String columnIsValidate = 'is_validate';
  // 'validado' | 'pendiente' — de qué lista del response vino
  // (items_validados / items_pendientes), no necesariamente igual a
  // is_validate.
  static const String columnOrigen = 'origen';

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnExpeditionId INTEGER,
        $columnPackingId INTEGER,
        $columnProductName TEXT,
        $columnProductCode TEXT,
        $columnBarcode TEXT,
        $columnOrderPacking INTEGER,
        $columnQuantity REAL,
        $columnUom TEXT,
        $columnIsValidate INTEGER DEFAULT 0,
        $columnOrigen TEXT
      );

      CREATE INDEX idx_expedicion_items_sueltos_expedition_id ON $tableName ($columnExpeditionId);
    ''';
  }
}
