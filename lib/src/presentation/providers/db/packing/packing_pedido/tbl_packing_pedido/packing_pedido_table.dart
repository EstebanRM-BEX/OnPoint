class PedidoPackTable {
  static const String tableName = 'tbl_pedido_pack';

  // Columnas de la tabla
  static const String columnBatchId = 'batch_id';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnObservacion = 'observacion';
  static const String columnFechaCreacion = 'fecha_creacion';
  static const String columnLocationId = 'location_id';
  static const String columnLocationName = 'location_name';
  static const String columnLocationBarcode = 'location_barcode';
  static const String columnLocationDestId = 'location_dest_id';
  static const String columnLocationDestName = 'location_dest_name';
  static const String columnLocationDestBarcode = 'location_dest_barcode';
  static const String columnProveedor = 'proveedor';
  static const String columnNumeroTransferencia = 'numero_transferencia';
  static const String columnPesoTotal = 'peso_total';
  static const String columnNumeroLineas = 'numero_lineas';
  static const String columnNumeroItems = 'numero_items';
  static const String columnState = 'state';
  static const String columnReferencia = 'referencia';
  static const String columnContacto = 'contacto';
  static const String columnContactoName = 'contacto_name';
  static const String columnCantidadProductos = 'cantidad_productos';
  static const String columnCantidadProductosTotal = 'cantidad_productos_total';
  static const String columnPriority = 'priority';
  static const String columnWarehouseId = 'warehouse_id';
  static const String columnWarehouseName = 'warehouse_name';
  static const String columnResponsableId = 'responsable_id';
  static const String columnResponsable = 'responsable';
  static const String columnPickingType = 'picking_type';
  static const String columnStartTimeTransfer = 'start_time_transfer';
  static const String columnEndTimeTransfer = 'end_time_transfer';
  static const String columnBackorderId = 'backorder_id';
  static const String columnBackorderName = 'backorder_name';
  static const String columnShowCheckAvailability = 'show_check_availability';
  static const String columnOrderTms = 'order_tms';
  static const String columnZonaEntregaTms = 'zona_entrega_tms';
  static const String columnZonaEntrega = 'zona_entrega';
  static const String columnNumeroPaquetes = 'numero_paquetes';
  static const String columnIsSelected = 'is_selected';
  static const String columnIsTerminate = 'is_terminate';

  //is_started
  static const String columnIsStarted = 'is_started';

    // create_backorder
  static const String columnCreateBackorder = 'create_backorder';


  // Método para crear la tabla
  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnBatchId INTEGER,
        $columnName TEXT,
        $columnObservacion TEXT,
        $columnFechaCreacion TEXT, -- Almacenar DateTime como TEXT (ISO 8601 string)
        $columnLocationId INTEGER,
        $columnLocationName TEXT,
        $columnLocationBarcode TEXT,
        $columnLocationDestId INTEGER,
        $columnLocationDestName TEXT,
        $columnLocationDestBarcode TEXT,
        $columnProveedor TEXT,
        $columnNumeroTransferencia TEXT,
        $columnPesoTotal INTEGER,
        $columnNumeroLineas INTEGER,
        $columnNumeroItems REAL,
        $columnState TEXT,
        $columnReferencia TEXT,
        $columnContacto TEXT,
        $columnContactoName TEXT,
        $columnCantidadProductos INTEGER,
        $columnCantidadProductosTotal INTEGER,
        $columnPriority TEXT,
        $columnWarehouseId INTEGER,
        $columnWarehouseName TEXT,
        $columnResponsableId INTEGER,
        $columnResponsable TEXT,
        $columnPickingType TEXT,
        $columnStartTimeTransfer TEXT,
        $columnEndTimeTransfer TEXT,
        $columnBackorderId INTEGER,
        $columnBackorderName TEXT,
        $columnShowCheckAvailability INTEGER, -- Booleans se almacenan como INTEGER (0 o 1)
        $columnOrderTms TEXT,
        $columnZonaEntregaTms TEXT,
        $columnZonaEntrega TEXT,
         $columnIsSelected INTEGER,
        $columnIsTerminate INTEGER,
        $columnCreateBackorder TEXT,
        $columnIsStarted INTEGER,
        $columnNumeroPaquetes INTEGER
      )
    ''';
  }
}
