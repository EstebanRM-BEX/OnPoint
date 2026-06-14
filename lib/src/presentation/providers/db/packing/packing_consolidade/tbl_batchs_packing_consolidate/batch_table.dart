// batch_packing_table.dart

class BatchPackingConsolidateTable {
  static const String tableName = 'tblbatchs_packing_consolidate';

  // Columnas de la tabla
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnScheduledDate = 'scheduleddate';
  static const String columnPickingTypeId = 'picking_type_id';
  static const String columnState = 'state';
  static const String columnUserId = 'user_id';
  static const String columnUserName = 'user_name';
  static const String columnCantidadPedidos = 'cantidad_pedidos';
  static const String columnIsSeparate = 'is_separate';
  static const String columnIsSelected = 'is_selected';
  static const String columnPedidoSeparateQty = 'pedido_separate_qty';
  static const String columnIndexList = 'index_list';
  static const String columnZonaEntrega = 'zona_entrega';
  static const String columnZonaEntregaTms = 'zona_entrega_tms';
  static const String columnTimeSeparateTotal = 'time_separate_total';
  static const String columnTimeSeparateStart = 'time_separate_start';
  static const String columnStartTimePack = 'start_time_pack';
  static const String columnEndTimePack = 'end_time_pack';
  static const String columnTimeSeparateEnd = 'time_separate_end';
  //maneja_temperatura
  static const String columnManejaTemperatura = 'maneja_temperatura';
  //temperatura
  static const String columnTemperatura = 'temperatura';
  static const String columnOrigins = 'origins';
  //propietario
  static const String columnPropietario = 'propietario';
  static const String columnManejoPropietario = 'manejo_propietario';

  // cantidad_total_pedidos
  // cantidad_total_productos
  static const String columnCantidadTotalPedidos = 'cantidad_total_pedidos';
  static const String columnCantidadTotalProductos = 'cantidad_total_productos';
//unidades_productos
  static const String columnUnidadesProductos = 'unidades_productos';
  // Método para crear la tabla
  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnName VARCHAR(255),
        $columnScheduledDate VARCHAR(255),
        $columnPickingTypeId VARCHAR(255),
        $columnState VARCHAR(255),
        $columnUserId INTEGER,
        $columnUserName VARCHAR(255),
        $columnCantidadPedidos INTEGER,
        $columnIsSeparate INTEGER, 
        $columnIsSelected INTEGER, 
        $columnPedidoSeparateQty INTEGER,
        $columnIndexList INTEGER,
        $columnZonaEntrega TEXT,
        $columnZonaEntregaTms TEXT,
        $columnTimeSeparateTotal DECIMAL(10,2),
        $columnTimeSeparateStart VARCHAR(255),
        $columnStartTimePack VARCHAR(255),
        $columnEndTimePack VARCHAR(255),
        $columnManejaTemperatura INTEGER,
        $columnTemperatura REAL,
        $columnOrigins TEXT,
        $columnCantidadTotalPedidos INTEGER,
        $columnCantidadTotalProductos REAL,
        $columnUnidadesProductos REAL,
        $columnTimeSeparateEnd VARCHAR(255),
        $columnPropietario TEXT,
        $columnManejoPropietario INTEGER DEFAULT 0
      )
    ''';
  }
}
