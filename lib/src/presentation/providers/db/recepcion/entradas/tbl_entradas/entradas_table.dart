class EntradasRepeccionTable {
  static const String tableName = 'tbl_entradas_recepcion';

  static const String columnId = 'id';

  static const String columnName = 'name';
  static const String columnFechaCreacion = 'fecha_creacion';
  static const String columnProveedorId = 'proveedor_id';
  static const String columnProveedor = 'proveedor';
  static const String columnLocationDestId = 'location_dest_id';
  static const String columnLocationDestName = 'location_dest_name';
  static const String columnPurchaseOrderId = 'purchase_order_id';
  static const String columnPurchaseOrderName = 'purchase_order_name';
  static const String columnNumeroEntrada = 'numero_entrada';
  static const String columnPesoTotal = 'peso_total';
  static const String columnNumeroLineas = 'numero_lineas';
  static const String columnNumeroItems = 'numero_items';
  static const String columnState = 'state';
  static const String columnOrigin = 'origin';
  static const String columnPriority = 'priority';
  static const String columnWarehouseId = 'warehouse_id';
  static const String columnWarehouseName = 'warehouse_name';
  static const String columnLocationId = 'location_id';
  static const String columnLocationName = 'location_name';
  static const String columnResponsableId = 'responsable_id';
  static const String columnResponsable = 'responsable';
  static const String columnPickingType = 'picking_type';

  static const String columnIsSelected = 'is_selected';
  static const String columnIsStarted = 'is_started';
  static const String columnIsfinis = 'is_finish';

  static const String columnDateFinish = 'end_time_reception';
  static const String columnDateStart = 'start_time_reception';

  static const String columnBackorderName = 'backorder_name';
  static const String columnBackorderId = 'backorder_id';

  //maneja_temperatura
  static const String columnManejaTemperatura = 'maneja_temperatura';
  //temperatura
  static const String columnTemperatura = 'temperatura';
  static const String columnType = 'type';
  //propietario
  static const String columnPropietario = 'propietario';
    static const String columnManejoPropietario = 'manejo_propietario';
  //create_backorder
  static const String columnCreateBackorder = 'create_backorder';

  static String createTable() {
    return '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY,
      $columnName TEXT,
      $columnFechaCreacion TEXT,
      $columnProveedorId INTEGER,
      $columnProveedor TEXT,
      $columnLocationDestId INTEGER,
      $columnLocationDestName TEXT,
      $columnPurchaseOrderId INTEGER,
      $columnPurchaseOrderName TEXT,
      $columnNumeroEntrada TEXT,
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
      $columnManejaTemperatura INTEGER,
      $columnTemperatura REAL,
      $columnType TEXT,
      $columnPropietario TEXT,
      $columnManejoPropietario INTEGER DEFAULT 0,
      $columnCreateBackorder TEXT,
      $columnBackorderId INTEGER

    )
    ''';
  }
}
