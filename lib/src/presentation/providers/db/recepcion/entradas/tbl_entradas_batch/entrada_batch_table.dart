class EntradaBatchTable {
  static const String tableName = 'tbl_entradas_recepcion_batch';

  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnOrderBy = 'order_by';
  static const String columnOrderPicking = 'order_picking';
  static const String columnFechaCreacion = 'fecha_creacion';
  static const String columnState = 'state';
  static const String columnPickingType = 'picking_type';
  static const String columnLocationId = 'location_id';
  static const String columnLocationName = 'location_name';
  static const String columnLocationBarcode = 'location_barcode';
  static const String columnZonaEntrega = 'zona_entrega';
  static const String columnProveedorId = 'proveedor_id';
  static const String columnProveedor = 'proveedor';
  static const String columnLocationDestId = 'location_dest_id';
  static const String columnLocationDestName = 'location_dest_name';
  static const String columnPurchaseOrderId = 'purchase_order_id';
  static const String columnPurchaseOrderName = 'purchase_order_name';
  static const String columnShowCheckAvailability = 'show_check_availability';
  static const String columnPickingTypeCode = 'picking_type_code';
  static const String columnResponsableId = 'responsable_id';
  static const String columnResponsable = 'responsable';
  static const String columnNumeroLineas = 'numero_lineas';
  static const String columnNumeroItems = 'numero_items';
  static const String columnWarehouseName = 'warehouse_name';
  static const String columnIsSelected = 'is_selected';
  static const String columnIsStarted = 'is_started';
  static const String columnIsfinis = 'is_finish';
  static const String columnDateFinish = 'end_time_reception';
  static const String columnDateStart = 'start_time_reception';
  //propietario
  static const String columnManejoPropietario = 'manejo_propietario';
  static const String columnPropietario = 'propietario';

  static String createTable() {
    return '''
  CREATE TABLE $tableName (
    $columnId INTEGER PRIMARY KEY,
    $columnName TEXT,
    $columnOrderBy TEXT,
    $columnOrderPicking TEXT,
    $columnFechaCreacion TEXT,
    $columnState TEXT,
    $columnPickingType TEXT,
    $columnLocationId INTEGER,
    $columnLocationName TEXT,
    $columnLocationBarcode TEXT,
    $columnZonaEntrega TEXT,
    $columnProveedorId INTEGER,
    $columnProveedor TEXT,
    $columnLocationDestId INTEGER,
    $columnLocationDestName TEXT,
    $columnPurchaseOrderId INTEGER,
    $columnPurchaseOrderName TEXT,
    $columnShowCheckAvailability INTEGER DEFAULT 0,
    $columnPickingTypeCode TEXT,
    $columnResponsableId INTEGER,
    $columnResponsable TEXT,
    $columnNumeroLineas INTEGER DEFAULT 0,
    $columnNumeroItems REAL,
    $columnWarehouseName TEXT DEFAULT '',
    $columnIsSelected INTEGER DEFAULT 0,
    $columnIsStarted INTEGER DEFAULT 0,
    $columnDateFinish TEXT,
    $columnIsfinis INTEGER DEFAULT 0,
    $columnPropietario TEXT,
    $columnManejoPropietario INTEGER DEFAULT 0,
    $columnDateStart TEXT
    )
    ''';
  }
}
