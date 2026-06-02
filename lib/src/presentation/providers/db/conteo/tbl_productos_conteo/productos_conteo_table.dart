class ProductosConteoTable {
  static const String tableName = 'tbl_productos_conteo';

  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnOrdenConteoId = 'orden_conteo_id';
  static const String columnBarcode = 'barcode';

  static String createTable() {
    return '''
    CREATE TABLE $tableName (
      $columnId INTEGER NOT NULL,
      $columnName TEXT,
      $columnOrdenConteoId INTEGER NOT NULL,
      $columnBarcode TEXT,
      PRIMARY KEY ($columnId, $columnOrdenConteoId)
    )
    ''';
  }
}
