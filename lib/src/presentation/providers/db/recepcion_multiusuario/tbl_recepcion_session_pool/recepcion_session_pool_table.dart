class RecepcionSessionPoolTable {
  static const String tableName = 'tbl_recepcion_session_pool';

  static const String columnTaskId = 'task_id';
  static const String columnSessionId = 'session_id';
  static const String columnProductId = 'product_id';
  static const String columnProductName = 'product_name';
  static const String columnDefaultCode = 'default_code';
  static const String columnBarcode = 'barcode';
  static const String columnQtyDemanded = 'qty_demanded';
  static const String columnQtyAsignada = 'qty_asignada';
  static const String columnQtyRecibida = 'qty_recibida';
  static const String columnQtyAvailable = 'qty_available';
  static const String columnUom = 'uom';
  static const String columnAsignacionesActivas = 'asignaciones_activas';
  static const String columnQtyClaimed = 'qty_claimed';
  static const String columnQtyDone = 'qty_done';

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnTaskId INTEGER PRIMARY KEY,
        $columnSessionId INTEGER,
        $columnProductId INTEGER,
        $columnProductName TEXT,
        $columnDefaultCode TEXT,
        $columnBarcode TEXT,
        $columnQtyDemanded REAL,
        $columnQtyAsignada REAL,
        $columnQtyRecibida REAL,
        $columnQtyAvailable REAL,
        $columnUom TEXT,
        $columnAsignacionesActivas INTEGER,
        $columnQtyClaimed REAL,
        $columnQtyDone REAL
      );

      CREATE INDEX idx_recepcion_session_pool_session_id ON $tableName ($columnSessionId);
    ''';
  }
}
