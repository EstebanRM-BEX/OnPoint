class ExpedicionPaquetesTable {
  static const String tableName = 'tbl_expedicion_paquetes';

  static const String columnId = 'id';
  static const String columnExpeditionId = 'expedition_id';
  static const String columnPackingId = 'packing_id';
  static const String columnPackageName = 'package_name';
  static const String columnPackingBarcode = 'packing_barcode';
  static const String columnPackingType = 'packing_type';
  static const String columnOrderPacking = 'order_packing';
  static const String columnIsValidate = 'is_validate';

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnExpeditionId INTEGER,
        $columnPackingId INTEGER,
        $columnPackageName TEXT,
        $columnPackingBarcode TEXT,
        $columnPackingType TEXT,
        $columnOrderPacking INTEGER,
        $columnIsValidate INTEGER DEFAULT 0
      );

      CREATE INDEX idx_expedicion_paquetes_expedition_id ON $tableName ($columnExpeditionId);
      CREATE INDEX idx_expedicion_paquetes_packing_id ON $tableName ($columnPackingId);
    ''';
  }
}
