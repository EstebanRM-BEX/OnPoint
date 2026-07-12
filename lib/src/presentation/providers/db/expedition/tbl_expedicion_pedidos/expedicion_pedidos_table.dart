class ExpedicionPedidosTable {
  static const String tableName = 'tbl_expedicion_pedidos';

  static const String columnExpeditionId = 'expedition_id';
  static const String columnNombre = 'nombre';
  static const String columnFecha = 'fecha';
  static const String columnCliente = 'cliente';
  static const String columnDocumentoOrigen = 'documento_origen';
  static const String columnNumeroLineas = 'numero_lineas';
  static const String columnTotalCantidades = 'total_cantidades';
  static const String columnNumeroPaquetes = 'numero_paquetes';
  static const String columnProductoSueltos = 'producto_sueltos';
  static const String columnTotalPeso = 'total_peso';
  static const String columnObservacion = 'observacion';
  static const String columnManejoPropietario = 'manejo_propietario';
  static const String columnPropietario = 'propietario';
  static const String columnEstado = 'estado';
  static const String columnWarehouseId = 'warehouse_id';
  static const String columnWarehouseName = 'warehouse_name';
  static const String columnResponsableId = 'responsable_id';
  static const String columnResponsable = 'responsable';
  static const String columnPickingType = 'picking_type';
  static const String columnStartTimeTransfer = 'start_time_transfer';
  static const String columnEndTimeTransfer = 'end_time_transfer';
  static const String columnZonaEntrega = 'zona_entrega';

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnExpeditionId INTEGER PRIMARY KEY,
        $columnNombre TEXT,
        $columnFecha TEXT,
        $columnCliente TEXT,
        $columnDocumentoOrigen TEXT,
        $columnNumeroLineas INTEGER,
        $columnTotalCantidades INTEGER,
        $columnNumeroPaquetes INTEGER,
        $columnProductoSueltos INTEGER,
        $columnTotalPeso REAL,
        $columnObservacion TEXT,
        $columnManejoPropietario INTEGER DEFAULT 0,
        $columnPropietario TEXT,
        $columnEstado TEXT,
        $columnWarehouseId INTEGER,
        $columnWarehouseName TEXT,
        $columnResponsableId INTEGER,
        $columnResponsable TEXT,
        $columnPickingType TEXT,
        $columnStartTimeTransfer TEXT,
        $columnEndTimeTransfer TEXT,
        $columnZonaEntrega TEXT
      );

      CREATE INDEX idx_expedicion_pedidos_fecha ON $tableName ($columnFecha);
    ''';
  }
}
