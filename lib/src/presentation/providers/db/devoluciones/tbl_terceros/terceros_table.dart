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

  /// Índices de la tabla, una sentencia por elemento (en Android `execute`
  /// corre solo la primera sentencia de un texto con varias). El escaneo de
  /// contacto/propietario busca por documento sin distinguir mayúsculas.
  static List<String> get indices => [
        'CREATE INDEX IF NOT EXISTS idx_terceros_document_nocase ON $tableName ($columnDocument COLLATE NOCASE)',
      ];
}
