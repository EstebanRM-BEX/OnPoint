class UbicacionesTable {
  static const String tableName = 'tblUbicaciones';

  static const String columnId = 'id';
  static const String columnBarcode = 'barcode';
  static const String columnName = 'name';
  static const String columnLocationId = 'location_id';
  static const String columnLocationName = 'location_name';
  static const String columnIdWarehouse = 'id_warehouse';
  static const String columnWarehouseName = 'warehouse_name';
  //is_a_dock_alter
  static const String columnIsADock = 'is_a_dock_alter';

  // Columna técnica para la estrategia de "Marca y Barrido"
  static const String columnIsSynced = 'is_synced';

  static String createTable() {
    return '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY,
      $columnBarcode TEXT,
      $columnName TEXT,
      $columnLocationId INTEGER,
      $columnLocationName TEXT,
      $columnIdWarehouse INTEGER,
      $columnWarehouseName TEXT,
      $columnIsADock INTEGER DEFAULT 0,
      $columnIsSynced INTEGER DEFAULT 0 
    );
  ''';
  }

  /// Índices de la tabla, una sentencia por elemento: en Android `execute`
  /// corre solo la primera sentencia de un texto con varias, así que no
  /// pueden ir dentro de [createTable].
  static List<String> get indices => [
        'CREATE INDEX IF NOT EXISTS idx_${tableName}_barcode ON $tableName ($columnBarcode)',
        'CREATE INDEX IF NOT EXISTS idx_${tableName}_name ON $tableName ($columnName)',
      ];
}
