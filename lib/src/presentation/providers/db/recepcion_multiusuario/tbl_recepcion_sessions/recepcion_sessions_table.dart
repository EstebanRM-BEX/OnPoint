class RecepcionSessionsTable {
  static const String tableName = 'tbl_recepcion_sessions';

  static const String columnSessionId = 'session_id';
  static const String columnName = 'name';
  static const String columnState = 'state';
  static const String columnPickingId = 'picking_id';
  static const String columnPickingName = 'picking_name';
  static const String columnProgressPercent = 'progress_percent';
  static const String columnPendingTasks = 'pending_tasks';
  static const String columnProveedorId = 'proveedor_id';
  static const String columnProveedor = 'proveedor';
  static const String columnPesoTotal = 'peso_total';
  static const String columnNumeroLineas = 'numero_lineas';
  static const String columnNumeroItems = 'numero_items';
  static const String columnOrigin = 'origin';
  static const String columnPriority = 'priority';
  static const String columnWarehouseId = 'warehouse_id';
  static const String columnWarehouseName = 'warehouse_name';
  static const String columnPickingType = 'picking_type';
  static const String columnBackorderId = 'backorder_id';
  static const String columnBackorderName = 'backorder_name';
  static const String columnShowCheckAvailability = 'show_check_availability';
  static const String columnManejaTemperatura = 'maneja_temperatura';
  static const String columnTemperatura = 'temperatura';
  static const String columnManejoPropietario = 'manejo_propietario';
  static const String columnPropietario = 'propietario';

  /// Columnas agregadas cuando la sesión trajo mucha más info que el id/
  /// nombre/picking iniciales. Se usa tanto en createTable() (instalación
  /// nueva) como en la migración ALTER TABLE (instalaciones existentes).
  static const List<String> _extraColumnsDdl = [
    '$columnState TEXT',
    '$columnProveedorId INTEGER',
    '$columnProveedor TEXT',
    '$columnPesoTotal REAL',
    '$columnNumeroLineas INTEGER',
    '$columnNumeroItems REAL',
    '$columnOrigin TEXT',
    '$columnPriority TEXT',
    '$columnWarehouseName TEXT',
    '$columnPickingType TEXT',
    '$columnBackorderId INTEGER',
    '$columnBackorderName TEXT',
    '$columnShowCheckAvailability INTEGER',
    '$columnManejaTemperatura INTEGER',
    '$columnTemperatura REAL',
    '$columnManejoPropietario INTEGER',
    '$columnPropietario TEXT',
  ];

  static List<String> get extraColumnsAlterStatements => _extraColumnsDdl
      .map((col) => 'ALTER TABLE $tableName ADD COLUMN $col')
      .toList();

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnSessionId INTEGER PRIMARY KEY,
        $columnName TEXT,
        $columnPickingId INTEGER,
        $columnPickingName TEXT,
        $columnWarehouseId INTEGER,
        $columnProgressPercent REAL,
        $columnPendingTasks INTEGER,
        ${_extraColumnsDdl.join(',\n        ')}
      );
    ''';
  }
}
