// batch_packing_table.dart

class BatchPackingTable {
  static const String tableName = 'tblbatchs_packing';

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
    //propietario
  static const String columnPropietario = 'propietario';
    static const String columnManejoPropietario = 'manejo_propietario';
  

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
        $columnPropietario TEXT,
        $columnManejoPropietario INTEGER DEFAULT 0,
        $columnTimeSeparateEnd VARCHAR(255)
      )
    ''';
  }
}
