class RecepcionSessionsTable {
  static const String tableName = 'tbl_recepcion_sessions';

  static const String columnSessionId = 'session_id';
  static const String columnName = 'name';
  static const String columnPickingId = 'picking_id';
  static const String columnPickingName = 'picking_name';
  static const String columnWarehouseId = 'warehouse_id';
  static const String columnProgressPercent = 'progress_percent';
  static const String columnPendingTasks = 'pending_tasks';

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnSessionId INTEGER PRIMARY KEY,
        $columnName TEXT,
        $columnPickingId INTEGER,
        $columnPickingName TEXT,
        $columnWarehouseId INTEGER,
        $columnProgressPercent REAL,
        $columnPendingTasks INTEGER
      );
    ''';
  }
}
