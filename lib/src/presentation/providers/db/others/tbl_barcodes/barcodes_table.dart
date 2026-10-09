class BarcodesPackagesTable {
  static const String tableName = 'tblbarcodes_packages';

  static const String columnId = 'id';
  static const String columnBatchId = 'batch_id';
  static const String columnIdMove = 'id_move';
  static const String columnIdProduct = 'id_product';
  static const String columnBarcode = 'barcode';
  static const String columnCantidad = 'cantidad';
  static const String columnBarcodeType = 'barcode_type';
  
  // ✅ NUEVO: Para estrategia Mark & Sweep
  static const String columnIsSynced = 'is_synced'; 

  static String createTable() {
    return '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY,
      $columnBatchId INTEGER,
      $columnIdMove INTEGER,
      $columnIdProduct INTEGER,
      $columnBarcode TEXT,
      $columnBarcodeType TEXT,
      $columnCantidad DECIMAL(10,2),
      $columnIsSynced INTEGER DEFAULT 0, -- Por defecto no sincronizado
      FOREIGN KEY ($columnBatchId) REFERENCES tblbatchs (id)
    );
  ''';
  }

  /// Índices de la tabla, una sentencia por elemento: en Android `execute`
  /// corre solo la primera sentencia de un texto con varias, así que no
  /// pueden ir dentro de [createTable].
  static List<String> get indices => [
        // ÍNDICE ÚNICO: Reemplaza la lógica manual de "buscar si existe".
        // Define qué combinación de campos hace que un registro sea único.
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_barcode_entry ON $tableName ($columnBatchId, $columnIdMove, $columnIdProduct, $columnBarcode, $columnBarcodeType)',
        // ÍNDICE DE LECTURA: Acelera getBarcodesProduct y similares
        'CREATE INDEX IF NOT EXISTS idx_barcodes_search ON $tableName ($columnBatchId, $columnIdProduct, $columnBarcodeType)',
      ];
}