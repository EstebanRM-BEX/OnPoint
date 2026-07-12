class ExpedicionItemsTable {
  static const String tableName = 'tbl_expedicion_items';

  static const String columnId = 'id';
  static const String columnExpeditionId = 'expedition_id';
  static const String columnPackingId = 'packing_id';
  static const String columnPackageName = 'package_name';
  static const String columnIsValidate = 'is_validate';
  static const String columnProductoId = 'producto_id';
  static const String columnProductName = 'product_name';
  static const String columnProductCode = 'product_code';
  static const String columnBarcode = 'barcode';
  static const String columnTracking = 'tracking';
  static const String columnDiasVencimiento = 'dias_vencimiento';
  static const String columnQuantity = 'quantity';
  static const String columnUom = 'uom';

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnExpeditionId INTEGER,
        $columnPackingId INTEGER,
        $columnPackageName TEXT,
        $columnIsValidate INTEGER DEFAULT 0,
        $columnProductoId INTEGER,
        $columnProductName TEXT,
        $columnProductCode TEXT,
        $columnBarcode TEXT,
        $columnTracking TEXT,
        $columnDiasVencimiento INTEGER,
        $columnQuantity REAL,
        $columnUom TEXT
      );

      CREATE INDEX idx_expedicion_items_packing_id ON $tableName ($columnPackingId);
      CREATE INDEX idx_expedicion_items_expedition_id ON $tableName ($columnExpeditionId);
    ''';
  }
}
