// batch_picking_table.dart

class BatchPickingTable {
  static const String tableName = 'tblbatchs';

  // Columnas de la tabla
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnType = 'type';
  static const String columnScheduledDate = 'scheduleddate';
  static const String columnPickingTypeId = 'picking_type_id';
  static const String columnMuelle = 'muelle';
  static const String columnBarcodeMuelle = 'barcode_muelle';
  static const String columnIdMuelle = 'id_muelle';
  static const String columnIdMuellePadre = 'id_muelle_padre';
  static const String columnState = 'state';
  static const String columnUserId = 'user_id';
  static const String columnUserName = 'user_name';
  static const String columnIsWave = 'is_wave';
  static const String columnIsSeparate = 'is_separate';
  static const String columnIsSelected = 'is_selected';
  static const String columnProductSeparateQty = 'product_separate_qty';
  static const String columnProductQty = 'product_qty';
  static const String columnIndexList = 'index_list';
  static const String columnIsSendOddo = 'is_send_oddo';
  static const String columnIsSendOddoDate = 'is_send_oddo_date';
  static const String columnOrderBy = 'order_by';
  static const String columnOrderPicking = 'order_picking';
  static const String columnCountItems = 'count_items';
  static const String columnTotalQuantityItems = 'total_quantity_items';
  static const String columnObservation = 'observation';
  static const String columnStartTimePick = 'start_time_pick';
  static const String columnEndTimePick = 'end_time_pick';
  static const String columnZonaEntrega = 'zona_entrega';
  



  // Método para crear la tabla
  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnName VARCHAR(255),
        $columnType VARCHAR(255),
        $columnScheduledDate VARCHAR(255),
        $columnPickingTypeId VARCHAR(255),
        $columnMuelle VARCHAR(255),
        $columnBarcodeMuelle VARCHAR(255),
        $columnIdMuelle INTEGER,
        $columnIdMuellePadre INTEGER,
        $columnState VARCHAR(255),
        $columnUserId VARCHAR(255),
        $columnUserName VARCHAR(255),
        $columnIsWave TEXT,
        $columnIsSeparate INTEGER, 
        $columnIsSelected INTEGER, 
        $columnProductSeparateQty INTEGER,
        $columnProductQty INTEGER,
        $columnIndexList INTEGER,
        $columnIsSendOddo INTEGER,
        $columnIsSendOddoDate VARCHAR(255),
        $columnOrderBy TEXT,
        $columnOrderPicking TEXT,
        $columnCountItems INTEGER,
        $columnTotalQuantityItems INTEGER,
        $columnObservation TEXT,
        $columnStartTimePick VARCHAR(255),
        $columnEndTimePick VARCHAR(255),
        $columnZonaEntrega TEXT
      )
    ''';
  }
}