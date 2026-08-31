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
  static const String columnTaskState = 'task_state';
  static const String columnTieneObservaciones = 'tiene_observaciones';

  /// Historial de asignaciones (`observaciones[]`) serializado como JSON —
  /// es una lista anidada de objetos, no vale la pena una tabla aparte solo
  /// para mostrarla en el tab "Terminados".
  static const String columnObservacionesJson = 'observaciones_json';

  /// Columnas agregadas cuando el pool empezó a traer historial de
  /// asignaciones por producto. Se usa tanto en createTable() (instalación
  /// nueva) como en la migración ALTER TABLE (instalaciones existentes).
  static const List<String> _extraColumnsDdl = [
    '$columnTaskState TEXT',
    '$columnTieneObservaciones INTEGER',
    '$columnObservacionesJson TEXT',
  ];

  static List<String> get extraColumnsAlterStatements => _extraColumnsDdl
      .map((col) => 'ALTER TABLE $tableName ADD COLUMN $col')
      .toList();

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
        $columnQtyDone REAL,
        ${_extraColumnsDdl.join(',\n        ')}
      );

      CREATE INDEX idx_recepcion_session_pool_session_id ON $tableName ($columnSessionId);
    ''';
  }
}
