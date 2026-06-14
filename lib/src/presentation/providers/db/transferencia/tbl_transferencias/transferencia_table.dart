class TransferenciaTable {
  static const String tableName = 'tbl_transferencias';

  static const String columnId = 'id';

  static const String columnName = 'name';
  static const String columnFechaCreacion = 'fecha_creacion';
  static const String columnLocationId = 'location_id';
  static const String columnLocationName = 'location_name';
  static const String columnLocationDestId = 'location_dest_id';
  static const String columnLocationDestName = 'location_dest_name';
  static const String columnNumeroTrasnferencia = 'numero_transferencia';
  static const String columnPesoTotal = 'peso_total';
  static const String columnNumeroLineas = 'numero_lineas';
  static const String columnNumeroItems = 'numero_items';
  static const String columnState = 'state';
  static const String columnOrigin = 'origin';
  static const String columnPriority = 'priority';
  static const String columnWarehouseId = 'warehouse_id';
  static const String columnWarehouseName = 'warehouse_name';
  static const String columnResponsableId = 'responsable_id';
  static const String columnResponsable = 'responsable';
  static const String columnPickingType = 'picking_type';
  static const String columnDateFinish = 'end_time_transfer';
  static const String columnDateStart = 'start_time_transfer';

  //valores para el estado de la transferencia
  static const String columnIsSelected = 'is_selected';
  static const String columnIsStarted = 'is_started';
  static const String columnIsfinis = 'is_finish';
  static const String columnBackorderName = 'backorder_name';
  static const String columnBackorderId = 'backorder_id';
  static const String columnShowCheckAvailability = 'show_check_availability';
  static const String columnProveedor = 'proveedor';
  //create_backorder
  static const String columnCreateBackorder = 'create_backorder';

  static const String columnType = 'type';

  //propietario
  static const String columnManejoPropietario = 'manejo_propietario';
  static const String columnPropietario = 'propietario';

  static String createTable() {
    return '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY,
      $columnName TEXT,
      $columnFechaCreacion TEXT,
      $columnLocationDestId INTEGER,
      $columnLocationDestName TEXT,
      $columnNumeroTrasnferencia TEXT,
      $columnPesoTotal REAL,
      $columnNumeroLineas INTEGER,
      $columnNumeroItems INTEGER,
      $columnState TEXT,
      $columnOrigin TEXT,
      $columnPriority TEXT,
      $columnWarehouseId INTEGER,
      $columnWarehouseName TEXT,
      $columnLocationId INTEGER,
      $columnLocationName TEXT,
      $columnResponsableId INTEGER,
      $columnResponsable TEXT,
      $columnPickingType TEXT,
      $columnIsSelected INTEGER,
      $columnIsStarted INTEGER,
      $columnDateFinish TEXT,
      $columnDateStart TEXT,
      $columnIsfinis INTEGER,
      $columnBackorderName TEXT,
      $columnBackorderId INTEGER,
      $columnProveedor TEXT,
      $columnType TEXT,
      $columnCreateBackorder TEXT,
      $columnPropietario TEXT,
      $columnManejoPropietario INTEGER DEFAULT 0,
      $columnShowCheckAvailability INTEGER
    )
    ''';
  }
}
