// tblpackages_table.dart

class PackagesTable {
  static const String tableName = 'tblpackages';

  // Columnas de la tabla
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnBatchId = 'batch_id';
  static const String columnPedidoId = 'pedido_id';
  static const String columnCantidadProductos = 'cantidad_productos';
  static const String columnIsSticker = 'is_sticker';
  static const String columnType = 'type'; // si es de type batch o pedido
  static const String columnConsecutivo = 'consecutivo';
  static const String columnTypePaquete = 'type_paquete';
  static const String columnPeso = 'peso';
  static const String columnPackingBarcode = 'packing_barcode';
  static const String columnLocationDestId = 'location_dest_id';
  static const String columnLocationDestName = 'location_dest_name';
  static const String columnLocationDestBarcode = 'location_dest_barcode';

  // Método para crear la tabla
  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnName VARCHAR(255),
        $columnBatchId INTEGER,
        $columnPedidoId INTEGER,
        $columnCantidadProductos REAL,
        $columnIsSticker INTEGER,
        $columnType TEXT,
        $columnConsecutivo TEXT,
        $columnTypePaquete TEXT,
        $columnPeso REAL,
        $columnPackingBarcode VARCHAR(255),
        $columnLocationDestId INTEGER,
        $columnLocationDestName VARCHAR(255),
        $columnLocationDestBarcode VARCHAR(255),
        FOREIGN KEY ($columnPedidoId) REFERENCES tblpedidos_packing (id)
      )
    ''';
  }
}
