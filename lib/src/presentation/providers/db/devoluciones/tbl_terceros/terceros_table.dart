class TercerosTable {
  static const String tableName = 'tbl_terceros';

  static const String columnId = 'id';
  static const String columnDocument = 'document';
  static const String columnSucursal = 'sucursal';
  static const String columnName = 'name';
  static const String columnAlmacen = 'almacen';

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnDocument TEXT,
        $columnSucursal TEXT,
        $columnName TEXT,
        $columnAlmacen TEXT
      )
    ''';
  }
}
