import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base SQLite propia del packing por pedido (`packing_pedido_v2.db`).
///
/// Va aparte de `DataBaseSqlite` a propósito: el módulo legacy, packing batch
/// y consolidado comparten tablas, y nada de lo que haga este feature debe
/// alterarlas. Esquema y versión propios.
@lazySingleton
class PackingPedidoDatabase {
  static const fileName = 'packing_pedido_v2.db';
  static const version = 1;

  static const tPedidos = 'pp_pedidos';
  static const tProductos = 'pp_productos';
  static const tPaquetes = 'pp_paquetes';
  static const tBarcodes = 'pp_barcodes';
  static const tMeta = 'pp_meta';

  /// Clave de pp_meta con el dueño de los datos (empresa + usuario).
  static const metaOwner = 'owner';

  PackingPedidoDatabase();

  /// Para tests: base ya abierta (p. ej. `sqflite_common_ffi` en memoria).
  PackingPedidoDatabase.withDatabase(Database db) : _db = db;

  Database? _db;
  Future<Database>? _opening;

  Future<Database> get database async {
    final db = _db;
    if (db != null && db.isOpen) return db;
    return _opening ??= _open().whenComplete(() => _opening = null);
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), fileName);
    final db = await openDatabase(
      path,
      version: version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = OFF'),
      onCreate: (db, _) => createSchema(db),
    );
    _db = db;
    return db;
  }

  /// Crea las tablas. Público para poder armar la base en tests.
  static Future<void> createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tMeta (
        key TEXT PRIMARY KEY,
        value TEXT
      )''');

    await db.execute('''
      CREATE TABLE $tPedidos (
        id INTEGER PRIMARY KEY,
        batch_id INTEGER,
        name TEXT,
        referencia TEXT,
        contacto_name TEXT,
        observacion TEXT,
        fecha_creacion TEXT,
        config_packing TEXT,
        priority TEXT,
        state TEXT,
        picking_type TEXT,
        location_id INTEGER,
        location_name TEXT,
        location_barcode TEXT,
        location_dest_id INTEGER,
        location_dest_name TEXT,
        location_dest_barcode TEXT,
        warehouse_id INTEGER,
        warehouse_name TEXT,
        location_name_cluster TEXT,
        location_barcode_cluster TEXT,
        proveedor TEXT,
        propietario TEXT,
        manejo_propietario INTEGER NOT NULL DEFAULT 0,
        cantidad_productos INTEGER,
        responsable_id INTEGER,
        responsable TEXT,
        backorder_id INTEGER,
        backorder_name TEXT,
        create_backorder TEXT,
        numero_lineas INTEGER,
        numero_items REAL,
        numero_paquetes INTEGER,
        order_tms TEXT,
        zona_entrega TEXT,
        zona_entrega_tms TEXT,
        start_time_transfer TEXT,
        end_time_transfer TEXT,
        is_selected INTEGER NOT NULL DEFAULT 0,
        is_started INTEGER NOT NULL DEFAULT 0,
        is_terminate INTEGER NOT NULL DEFAULT 0
      )''');

    // Una fila por parte de un stock.move: al dividir, un mismo id_move queda
    // en varias filas. Toda operación va por `id`.
    await db.execute('''
      CREATE TABLE $tProductos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pedido_id INTEGER NOT NULL,
        batch_id INTEGER,
        id_move INTEGER NOT NULL,
        id_product INTEGER NOT NULL,
        product_name TEXT,
        product_code TEXT,
        barcode TEXT,
        lote_id INTEGER,
        lote_name TEXT,
        expire_date TEXT,
        tracking TEXT,
        unidades TEXT,
        weight REAL,
        id_location INTEGER,
        location_name TEXT,
        barcode_location TEXT,
        id_location_dest INTEGER,
        location_dest_name TEXT,
        quantity REAL NOT NULL,
        quantity_separate REAL NOT NULL DEFAULT 0,
        estado TEXT NOT NULL,
        certificado INTEGER NOT NULL DEFAULT 0,
        is_product_split INTEGER NOT NULL DEFAULT 0,
        id_package INTEGER,
        package_name TEXT,
        observation TEXT,
        maneja_temperatura INTEGER NOT NULL DEFAULT 0,
        temperatura REAL,
        image TEXT,
        image_novedad TEXT,
        location_ok INTEGER NOT NULL DEFAULT 0,
        product_ok INTEGER NOT NULL DEFAULT 0,
        quantity_ok INTEGER NOT NULL DEFAULT 0,
        time_separate_start TEXT,
        time_separate REAL NOT NULL DEFAULT 0
      )''');
    await db.execute(
      'CREATE INDEX idx_pp_productos_pedido ON $tProductos (pedido_id, estado)',
    );
    await db.execute(
      'CREATE INDEX idx_pp_productos_move ON $tProductos (pedido_id, id_move)',
    );

    await db.execute('''
      CREATE TABLE $tPaquetes (
        id INTEGER PRIMARY KEY,
        pedido_id INTEGER NOT NULL,
        batch_id INTEGER,
        name TEXT,
        packing_barcode TEXT,
        consecutivo TEXT,
        cantidad_productos INTEGER,
        is_sticker INTEGER NOT NULL DEFAULT 0,
        is_certificate INTEGER NOT NULL DEFAULT 0,
        type_paquete TEXT,
        peso REAL,
        location_dest_id INTEGER,
        location_dest_name TEXT,
        location_dest_barcode TEXT
      )''');
    await db.execute(
      'CREATE INDEX idx_pp_paquetes_pedido ON $tPaquetes (pedido_id)',
    );

    await db.execute('''
      CREATE TABLE $tBarcodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pedido_id INTEGER NOT NULL,
        id_move INTEGER,
        id_product INTEGER NOT NULL,
        barcode TEXT NOT NULL,
        cantidad REAL NOT NULL DEFAULT 1
      )''');
    await db.execute(
      'CREATE INDEX idx_pp_barcodes_producto ON $tBarcodes (pedido_id, id_product)',
    );
  }

  /// Si los datos guardados son de otra empresa o de otro usuario, borra
  /// todo. Así no se cruzan pedidos entre sesiones sin tocar el logout global.
  Future<void> ensureOwner(String owner) async {
    final db = await database;
    final rows = await db.query(
      tMeta,
      where: 'key = ?',
      whereArgs: [metaOwner],
      limit: 1,
    );
    final actual = rows.isEmpty ? null : rows.first['value'] as String?;
    if (actual == owner) return;

    await db.transaction((txn) async {
      await txn.delete(tBarcodes);
      await txn.delete(tProductos);
      await txn.delete(tPaquetes);
      await txn.delete(tPedidos);
      await txn.insert(tMeta, {
        'key': metaOwner,
        'value': owner,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }
}
