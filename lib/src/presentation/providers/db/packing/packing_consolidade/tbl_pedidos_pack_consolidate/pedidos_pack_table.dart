// pedidos_packing_table.dart

class PedidosPackingConsolidateTable {
  static const String tableName = 'tblpedidos_packing_consolidate';

  // Columnas de la tabla
  static const String columnId = 'id';
  static const String columnBatchId = 'batch_id';
  static const String columnName = 'name';
  static const String columnReferencia = 'referencia';
  static const String columnFecha = 'fecha';
  static const String columnContacto = 'contacto';
  static const String columnContactoName = 'contacto_name';
  static const String columnTipoOperacion = 'tipo_operacion';
  static const String columnCantidadProductos = 'cantidad_productos';
  static const String columnNumeroPaquetes = 'numero_paquetes';
  static const String columnIsSelected = 'is_selected';
  static const String columnIsTerminate = 'is_terminate';
  static const String columnIsZonaEntrega = 'zona_entrega';
  static const String columnIsZonaEntregaTms = 'zona_entrega_tms';
  static const String columnType = 'type'; // si es de type batch o pedido
        //propietario
  static const String columnPropietario = 'propietario';
    static const String columnManejoPropietario = 'manejo_propietario';

  //pedidos
  static const String columnPedidos = 'pedidos';





  // Método para crear la tabla
  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnBatchId INTEGER,
        $columnName TEXT,
        $columnReferencia TEXT,
        $columnFecha TEXT,
        $columnContacto TEXT,
        $columnContactoName TEXT,
        $columnTipoOperacion TEXT,
        $columnCantidadProductos REAL,
        $columnNumeroPaquetes INTEGER,
        $columnIsSelected INTEGER,
        $columnIsTerminate INTEGER,
        $columnIsZonaEntrega TEXT,
        $columnIsZonaEntregaTms TEXT,
        $columnType TEXT,
        $columnPedidos TEXT,
                        $columnPropietario TEXT,
        $columnManejoPropietario INTEGER DEFAULT 0,
        FOREIGN KEY ($columnBatchId) REFERENCES tblbatchs_packing (id)
      )
    ''';
  }
}
