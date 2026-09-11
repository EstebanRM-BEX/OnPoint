class TransferenciaSessionsTable {
  static const String tableName = 'tbl_transferencia_sessions';

  static const String columnSessionId = 'session_id';
  static const String columnName = 'name';
  static const String columnState = 'state';
  static const String columnPickingId = 'picking_id';
  static const String columnPickingName = 'picking_name';
  static const String columnPickingState = 'picking_state';
  static const String columnProgressPercent = 'progress_percent';
  static const String columnPendingTasks = 'pending_tasks';
  static const String columnStartTime = 'start_time';
  static const String columnEndTime = 'end_time';
  static const String columnMaxClaimsPerUser = 'max_claims_per_user';
  static const String columnClaimTtlMinutes = 'claim_ttl_minutes';
  static const String columnClaimChunkMode = 'claim_chunk_mode';
  static const String columnClaimChunkQty = 'claim_chunk_qty';
  static const String columnQtyDemandedTotal = 'qty_demanded_total';
  static const String columnQtyAlmacenadaTotal = 'qty_almacenada_total';
  static const String columnQtyRecibidaTotal = 'qty_recibida_total';
  static const String columnQtyAsignadaTotal = 'qty_asignada_total';
  static const String columnQtyPendienteTotal = 'qty_pendiente_total';
  static const String columnTaskCount = 'task_count';
  static const String columnClaimCount = 'claim_count';
  static const String columnProveedorId = 'proveedor_id';
  static const String columnProveedor = 'proveedor';
  static const String columnPesoTotal = 'peso_total';
  static const String columnNumeroLineas = 'numero_lineas';
  static const String columnNumeroItems = 'numero_items';
  static const String columnOrigin = 'origin';
  static const String columnOriginPickingId = 'origin_picking_id';
  static const String columnOriginPickingName = 'origin_picking_name';
  static const String columnPriority = 'priority';
  static const String columnWarehouseId = 'warehouse_id';
  static const String columnWarehouseName = 'warehouse_name';
  static const String columnPickingType = 'picking_type';
  static const String columnPickingTypeCode = 'picking_type_code';
  static const String columnBackorderId = 'backorder_id';
  static const String columnBackorderName = 'backorder_name';
  static const String columnShowCheckAvailability = 'show_check_availability';
  static const String columnManejaTemperatura = 'maneja_temperatura';
  static const String columnTemperatura = 'temperatura';
  static const String columnManejoPropietario = 'manejo_propietario';
  static const String columnPropietario = 'propietario';
  static const String columnLocationOrigenId = 'location_origen_id';
  static const String columnLocationOrigenName = 'location_origen_name';
  static const String columnLocationOrigenBarcode = 'location_origen_barcode';
  static const String columnLocationEntradaId = 'location_entrada_id';
  static const String columnLocationEntradaName = 'location_entrada_name';
  static const String columnLocationDestId = 'location_dest_id';
  static const String columnLocationDestName = 'location_dest_name';
  static const String columnLocationStockId = 'location_stock_id';
  static const String columnLocationStockName = 'location_stock_name';
  static const String columnEsIntAlmacenamiento = 'es_int_almacenamiento';
  static const String columnRecepcionUnPaso = 'recepcion_un_paso';

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnSessionId INTEGER PRIMARY KEY,
        $columnName TEXT,
        $columnState TEXT,
        $columnPickingId INTEGER,
        $columnPickingName TEXT,
        $columnPickingState TEXT,
        $columnProgressPercent REAL,
        $columnPendingTasks INTEGER,
        $columnStartTime TEXT,
        $columnEndTime TEXT,
        $columnMaxClaimsPerUser INTEGER,
        $columnClaimTtlMinutes INTEGER,
        $columnClaimChunkMode TEXT,
        $columnClaimChunkQty REAL,
        $columnQtyDemandedTotal REAL,
        $columnQtyAlmacenadaTotal REAL,
        $columnQtyRecibidaTotal REAL,
        $columnQtyAsignadaTotal REAL,
        $columnQtyPendienteTotal REAL,
        $columnTaskCount INTEGER,
        $columnClaimCount INTEGER,
        $columnProveedorId INTEGER,
        $columnProveedor TEXT,
        $columnPesoTotal REAL,
        $columnNumeroLineas INTEGER,
        $columnNumeroItems REAL,
        $columnOrigin TEXT,
        $columnOriginPickingId INTEGER,
        $columnOriginPickingName TEXT,
        $columnPriority TEXT,
        $columnWarehouseId INTEGER,
        $columnWarehouseName TEXT,
        $columnPickingType TEXT,
        $columnPickingTypeCode TEXT,
        $columnBackorderId INTEGER,
        $columnBackorderName TEXT,
        $columnShowCheckAvailability INTEGER,
        $columnManejaTemperatura INTEGER,
        $columnTemperatura REAL,
        $columnManejoPropietario INTEGER,
        $columnPropietario TEXT,
        $columnLocationOrigenId INTEGER,
        $columnLocationOrigenName TEXT,
        $columnLocationOrigenBarcode TEXT,
        $columnLocationEntradaId INTEGER,
        $columnLocationEntradaName TEXT,
        $columnLocationDestId INTEGER,
        $columnLocationDestName TEXT,
        $columnLocationStockId INTEGER,
        $columnLocationStockName TEXT,
        $columnEsIntAlmacenamiento INTEGER,
        $columnRecepcionUnPaso INTEGER
      );
    ''';
  }
}
