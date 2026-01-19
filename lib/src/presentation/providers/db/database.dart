// ignore_for_file: avoid_print, depend_on_referenced_packages, unnecessary_string_interpolations, unnecessary_brace_in_string_interps, unrelated_type_equality_checks, unnecessary_null_comparison, prefer_conditional_assignment

import 'package:wms_app/src/presentation/providers/db/conteo/tbl_categories_orden_conteo/categories_orden_repository.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_categories_orden_conteo/categories_orden_table.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_ordenes/orden_repository.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_ordenes/orden_table.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_products_ordenes_conteo/product_orden_conteo_repository.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_products_ordenes_conteo/product_orden_conteo_table.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_ubicaciones_orden_conteo/ubicaciones_conteo_repository.dart';
import 'package:wms_app/src/presentation/providers/db/conteo/tbl_ubicaciones_orden_conteo/ubicaciones_conteo_table.dart';
import 'package:wms_app/src/presentation/providers/db/devoluciones/tbl_product/product_devolucion_repository.dart';
import 'package:wms_app/src/presentation/providers/db/devoluciones/tbl_product/product_devolucion_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_repository.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_barcodes/barcodes_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_barcodes/barcodes_table.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_ubicaciones/ubicaciones_table.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_warehouses/tbl_warehouse_table.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_warehouses/warehouse_repository.dart';
import 'package:wms_app/src/presentation/providers/db/packing/packing_consolidade/tbl_batchs_packing_consolidate/batch_packing_repository.dart';
import 'package:wms_app/src/presentation/providers/db/packing/packing_consolidade/tbl_batchs_packing_consolidate/batch_table.dart';
import 'package:wms_app/src/presentation/providers/db/packing/packing_consolidade/tbl_pedidos_pack_consolidate/pedidos_pack_repository.dart';
import 'package:wms_app/src/presentation/providers/db/packing/packing_consolidade/tbl_pedidos_pack_consolidate/pedidos_pack_table.dart';
import 'package:wms_app/src/presentation/providers/db/packing/packing_pedido/tbl_packing_pedido/packing_pedido_repository.dart';
import 'package:wms_app/src/presentation/providers/db/packing/packing_pedido/tbl_packing_pedido/packing_pedido_table.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_batchs_packing/batch_packing_repository.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_batchs_packing/batch_table.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_package_pack/package_repository.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_package_pack/package_table.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_products_pedido/productos_pedido_pack_repository.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_products_pedido/productos_pedido_pack_table.dart';
import 'package:wms_app/src/presentation/providers/db/picking/tbl_batch/batch_picking_repository.dart';
import 'package:wms_app/src/presentation/providers/db/picking/tbl_batch/batch_picking_table.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_configurations/configuration_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_configurations/configuration_table.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_novedades/novedades_repoisitory.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_novedades/novedades_table.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_pedidos_pack/pedidos_pack_repository.dart';
import 'package:wms_app/src/presentation/providers/db/packing/tbl_pedidos_pack/pedidos_pack_table.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_doc_origin/doc_origin_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_doc_origin/doc_origin_table.dart';
import 'package:wms_app/src/presentation/providers/db/picking/tbl_pick/picking_pick_repository.dart';
import 'package:wms_app/src/presentation/providers/db/picking/tbl_pick/picking_pick_table.dart';
import 'package:wms_app/src/presentation/providers/db/picking/tbl_pick_products/pick_products_repository.dart';
import 'package:wms_app/src/presentation/providers/db/picking/tbl_pick_products/pick_products_table.dart';
import 'package:wms_app/src/presentation/providers/db/picking/tbl_submuelles/submuelles_repository.dart';
import 'package:wms_app/src/presentation/providers/db/picking/tbl_submuelles/submuelles_table.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_urlrecientes/urlrecientes_repository.dart';
import 'package:wms_app/src/presentation/providers/db/others/tbl_urlrecientes/urlrecientes_table.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_entradas/entradas_repository.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_entradas/entradas_table.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_entradas_batch/entrada_batch_repository.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_entradas_batch/entrada_batch_table.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_product_entrada/product_entrada_repository.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_product_entrada/product_entrada_table.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_product_entrada_batch/product_entrada_batch_table.dart';
import 'package:wms_app/src/presentation/providers/db/recepcion/entradas/tbl_product_entrada_batch/product_entrada_repository.dart';
import 'package:wms_app/src/presentation/providers/db/transferencia/create_transfer/tbl_create_transfer_products/product_create_transfer_repository.dart';
import 'package:wms_app/src/presentation/providers/db/transferencia/create_transfer/tbl_create_transfer_products/product_create_transfer_table.dart';
import 'package:wms_app/src/presentation/providers/db/transferencia/tbl_product_transferencia/product_transferencia_repository.dart';
import 'package:wms_app/src/presentation/providers/db/transferencia/tbl_product_transferencia/product_transferencia_table.dart';
import 'package:wms_app/src/presentation/providers/db/transferencia/tbl_transferencias/transferencia_repository.dart';
import 'package:wms_app/src/presentation/providers/db/transferencia/tbl_transferencias/transferencia_table.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/BatchWithProducts_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

import 'package:sqflite/sqflite.dart';

class DataBaseSqlite {
  static final DataBaseSqlite _instance = DataBaseSqlite._internal();
  factory DataBaseSqlite() => _instance;
  DataBaseSqlite._internal();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await initDB();
    return _database;
  }

// Método para inicializar la base de datos si no está inicializada
  Future<Database> initDB() async {
    if (_database != null) return _database!;

    _database = await openDatabase(
      'wmsapp.db',
      version: 19,
      onConfigure: (db) async {
        try {
          // ✅ CORRECCIÓN: Usamos rawQuery porque este PRAGMA devuelve el valor "wal"
          await db.rawQuery('PRAGMA journal_mode = WAL;');
          // Este usualmente no retorna, pero por seguridad puedes usar execute o rawQuery
          await db.execute('PRAGMA synchronous = NORMAL;');
          // Este tampoco retorna filas
          await db.execute('PRAGMA cache_size = -10000;');
        } catch (e) {
          print("Error configurando PRAGMA: $e");
        }
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    return _database!;
  }

  Future<void> _createDB(Database db, int version) async {
    //* tabla de batchs de packing
    await db.execute(BatchPackingTable.createTable());
    //*tabla de productos de un pedido de packing
    await db.execute(ProductosPedidosTable.createTable());
    //*tabla de barcodes de los productos
    await db.execute(BarcodesPackagesTable.createTable());
    //* tabla de paquetes de packing
    await db.execute(PackagesTable.createTable());
    //* tabla de batchs de picking
    await db.execute(BatchPickingTable.createTable());
    //* tabla de pedidos de packing
    await db.execute(PedidosPackingTable.createTable());
    //tabla de configuracion del usuario
    await db.execute(ConfigurationsTable.createTable());
    //tabla de urls recientes
    await db.execute(UrlsRecientesTable.createTable());
    //tabla para submuelles
    await db.execute(SubmuellesTable.createTable());
    //tabla para novedades
    await db.execute(NovedadesTable.createTable());
    //tabla para las entradas de mercancia
    await db.execute(ProductRecepcionTable.createTable());
    //tabla para las entradas de mercancia
    await db.execute(EntradasRepeccionTable.createTable());
    //tabla para las transferencias
    await db.execute(TransferenciaTable.createTable());
    //tabla para los productos de una transferencia
    await db.execute(ProductTransferenciaTable.createTable());
    //table para las ubicaciones
    await db.execute(UbicacionesTable.createTable());
    //table para las barcodes inventario
    await db.execute(BarcodesInventarioTable.createTable());
    //table para las producto de inventario
    await db.execute(ProductInventarioTable.createTable());
    //tabla para crear los almacenes
    await db.execute(WarehouseTable.createTable());
    //table de documentos de origen de picking
    await db.execute(DocOriginTable.createTable());
    //tabla de picking por pick
    await db.execute(PickingPickTable.createTable());
    //tabla de productos por pick
    await db.execute(PickProductsTable.createTable());
    //tabla de recepciones por batch
    await db.execute(EntradaBatchTable.createTable());
    //tabal de productos de recepcion por batch
    await db.execute(ProductRecepcionBatchTable.createTable());
    //tabla de pedidos por packing
    await db.execute(PedidoPackTable.createTable());
    //tabla de prductos de una devolucion
    await db.execute(ProductDevolucionTable.createTable());
    // tabla de ordenes de conteo
    await db.execute(OrdenTable.createTable());

    //tabla de productos de un conteo
    await db.execute(ProductosOrdenConteoTable.createTable());

    //* tabla de categorias de un conteo
    await db.execute(CategoriasConteoTable.createTable());

    //* tabla de ubicaciones de un conteo
    await db.execute(UbicacionesConteoTable.createTable());

    //*tabla de los productos para crear una transferencia
    await db.execute(ProductCreateTransferTable.createTable());

    //* tabla de productos de un batch packing consolidade
    await db.execute(BatchPackingConsolidateTable.createTable());

    await db.execute(PedidosPackingConsolidateTable.createTable());

    //* tabla de productos de un batch picking
    await db.execute('''
      CREATE TABLE tblbatch_products (
        id INTEGER PRIMARY KEY,
        type TEXT,
        id_product INTEGER,
        batch_id INTEGER,
        expire_date VARCHAR(255),
        product_id INTEGER,
        picking_id TEXT,
        lot_id TEXT,
        lote_id INTEGER,
        id_move INTEGER,
        location_id TEXT,
        location_dest_id TEXT,
        id_location_dest INTEGER,
        quantity INTEGER,
        barcode TEXT,
        rimoval_priority INTEGER,
        barcode_location_dest TEXT,
        barcode_location TEXT,
        quantity_separate INTEGER,
        is_selected INTEGER,
        is_separate INTEGER,
        is_pending INTEGER,
        order_product INTEGER,
        time_separate DECIMAL(10,2),
        time_separate_start VARCHAR(255),
        time_separate_end VARCHAR(255),
        origin VARCHAR(255),
        observation TEXT,
        unidades TEXT,
        weight INTEGER,
        is_muelle INTEGER,
        muelle_id INTEGER,
        is_location_is_ok INTEGER,
        product_is_ok INTEGER,
        is_quantity_is_ok INTEGER,
        location_dest_is_ok INTEGER,
        fecha_transaccion VARCHAR(255),
        is_send_odoo INTEGER,
        is_send_odoo_date VARCHAR(255),
        FOREIGN KEY (batch_id) REFERENCES tblbatchs (id)
          )
     ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migración para la versión 9

    if (oldVersion < 14) {
      //solucion para cuando la version no tiene la tabla de maestra de productos de inventario
      print('Migrando la base de datos a la versión 14...');
      try {
        // Añadir la columna 'category' a la tabla ProductInventarioTable
        await db.execute('''
          ALTER TABLE ${ProductInventarioTable.tableName}
          ADD COLUMN ${ProductInventarioTable.columnCategory} TEXT;
        ''');
        print(
            '✅ Columna ${ProductInventarioTable.columnCategory} añadida a ${ProductInventarioTable.tableName}.');
      } catch (e) {
        print(
            '❌ Error al añadir la columna ${ProductInventarioTable.columnCategory}, es posible que ya exista.');
      }
    }

    if (oldVersion < 15) {
      //solucion para cuabndo no tebnemos el campo de accessProductionModule en la tabla de configuraciones
      print('Migrando la base de datos a la versión 15...');
      try {
        // Añadir la columna 'access_production_module' a la tabla ConfigurationsTable
        await db.execute('''
          ALTER TABLE ${ConfigurationsTable.tableName}
          ADD COLUMN ${ConfigurationsTable.columnAccessProductionModule} INTEGER;
        ''');
        print(
            '✅ Columna ${ConfigurationsTable.columnAccessProductionModule} añadida a ${ConfigurationsTable.tableName}.');
      } catch (e) {
        print(
            '❌ Error al añadir la columna ${ConfigurationsTable.columnAccessProductionModule}, es posible que ya exista.');
      }
    }
    if (oldVersion < 16) {
      // O tu siguiente versión
      try {
        // Agregar columna para estrategia Mark & Sweep
        await db.execute(
            'ALTER TABLE tblUbicaciones ADD COLUMN is_synced INTEGER DEFAULT 0;');

        // Agregar Índices para velocidad
        await db.execute(
            'CREATE INDEX idx_tblUbicaciones_barcode ON tblUbicaciones (barcode);');

        print('Migrando Barcodes: Agregando is_synced e Índices...');

        // 1. Agregar columna para sincronización
        await db.execute(
            'ALTER TABLE ${BarcodesPackagesTable.tableName} ADD COLUMN ${BarcodesPackagesTable.columnIsSynced} INTEGER DEFAULT 0;');

        // 2. Índice para búsquedas rápidas (Lectura)
        await db.execute(
            'CREATE INDEX idx_barcodes_search ON ${BarcodesPackagesTable.tableName} (${BarcodesPackagesTable.columnBatchId}, ${BarcodesPackagesTable.columnIdProduct}, ${BarcodesPackagesTable.columnBarcodeType});');

        // 3. ÍNDICE ÚNICO (Critico para Escritura Rápida)
        // Esto permite usar ConflictAlgorithm.replace. Si intentas insertar un duplicado de estos campos, lo actualizará en vez de crear otro.
        await db.execute('''
          CREATE UNIQUE INDEX idx_unique_barcode_entry ON ${BarcodesPackagesTable.tableName} 
          (${BarcodesPackagesTable.columnBatchId}, ${BarcodesPackagesTable.columnIdMove}, ${BarcodesPackagesTable.columnIdProduct}, ${BarcodesPackagesTable.columnBarcode}, ${BarcodesPackagesTable.columnBarcodeType});
        ''');

        // 1. Agregar columna de sincronización
        await db.execute(
            'ALTER TABLE tblbarcodes_inventario ADD COLUMN is_synced INTEGER DEFAULT 0;');

        // 2. ÍNDICE ÚNICO (Para escritura rápida):
        // Define que la combinación (Producto + Barcode) es única.
        // Esto permite que 'ConflictAlgorithm.replace' funcione.
        await db.execute('''
          CREATE UNIQUE INDEX idx_unique_barcode_inv ON tblbarcodes_inventario 
          (id_product, barcode);
        ''');

        // 3. ÍNDICE DE LECTURA (Para búsqueda rápida):
        await db.execute(
            'CREATE INDEX idx_search_inv_product ON tblbarcodes_inventario (id_product);');

        // 1. Agregar columna para Mark & Sweep
        await db.execute(
            'ALTER TABLE tblproductos_inventario ADD COLUMN is_synced INTEGER DEFAULT 0;');

        // 2. ÍNDICE ÚNICO (Critico para Upsert):
        // Define que la combinación (Producto + Lote + Ubicación) es única.
        // Si llega el mismo producto en el mismo lote y ubicación, se actualiza el stock/datos.
        await db.execute('''
          CREATE UNIQUE INDEX idx_unique_inventory_stock ON tblproductos_inventario 
          (product_id, lot_id, location_id);
        ''');

        // 3. ÍNDICES DE LECTURA (Búsquedas instantáneas):
        await db.execute(
            'CREATE INDEX idx_inv_barcode ON tblproductos_inventario (barcode);');
        await db.execute(
            'CREATE INDEX idx_inv_product_id ON tblproductos_inventario (product_id);');

        print('✅ Optimización de Barcodes completada.');

        print('🚀 Migrando Configuraciones: Optimizando...');
        await db.execute(
            'ALTER TABLE tblconfigurations ADD COLUMN is_synced INTEGER DEFAULT 0;');
        // PK is already an index.
        print('✅ Optimización Configuraciones completada.');
        await db.execute(
            'ALTER TABLE tblnovedades ADD COLUMN is_synced INTEGER DEFAULT 0;');

        // Nota: Como 'id' ya es PRIMARY KEY, SQLite crea un índice único interno automáticamente.
        // No necesitamos crear un índice adicional para que funcione el conflicto por ID.

        print('✅ Optimización Novedades completada.');
        // 1. Agregar columna para Mark & Sweep
        await db.execute(
            'ALTER TABLE tblproductos_devolucion ADD COLUMN is_synced INTEGER DEFAULT 0;');

        // 2. ÍNDICE ÚNICO (Crítico para Upsert):
        // Define que un Producto con un Lote específico es único en la lista de devoluciones.
        // Esto permite actualizar automáticamente si el registro ya existe.
        await db.execute('''
          CREATE UNIQUE INDEX idx_unique_devolucion 
          ON tblproductos_devolucion (product_id, lot_id);
        ''');

        // 3. ÍNDICES DE LECTURA (Búsquedas rápidas):
        await db.execute(
            'CREATE INDEX idx_dev_barcode ON tblproductos_devolucion (barcode);');

        print('✅ Optimización Devoluciones completada.');

        print('🚀 Migrando Barcodes: Creando restricción única estricta...');

        // 1. Borramos índices viejos si existen para evitar conflictos
        await db.execute('DROP INDEX IF EXISTS idx_unique_barcode_entry;');

        // 2. CREAR EL ÍNDICE ÚNICO ESTRICTO
        // Esta es la "regla" que ConflictAlgorithm.replace va a obedecer.
        // Solo sobrescribirá si COINCIDEN TODOS estos campos.
        // Si cambia aunque sea el id_move, creará uno nuevo.
        await db.execute('''
          CREATE UNIQUE INDEX idx_strict_barcode_validation ON tblbarcodes_packages 
          (batch_id, id_move, id_product, barcode, barcode_type);
        ''');

        print('✅ Restricción de unicidad aplicada correctamente.');
      } catch (e) {
        print("Error actualizando UbicacionesTable: $e");
      }
    }

    if (oldVersion < 17) {
      //observacion en picking pick
      try {
        await db.execute('''
          ALTER TABLE ${PickingPickTable.columnObservacion}
        ''');

// observacion en packing pack
        await db.execute('''
          ADD COLUMN ${PedidoPackTable.columnObservacion} TEXT;
        ''');
      } catch (e) {
        print("Error actualizando UbicacionesTable: $e");
      }
    }
    if (oldVersion < 18) {
      //añadir campo de type picking en la tabla de batch products
      try {
        await db.execute('''
          ALTER TABLE tblbatch_products
          ADD COLUMN type TEXT;
        ''');
      } catch (e) {
        print("Error actualizando tblbatch_products: $e");
      }
    }
    if (oldVersion < 19) {
      //añadir campo de type batch picking en la tabla de tblbatchs
      try {
        await db.execute('''
          ALTER TABLE tblbatchs
          ADD COLUMN type TEXT;
        ''');
      } catch (e) {
        print("Error actualizando tblbatchs: $e");
      }
    }
  }

  //todo repositorios de las tablas
  // Método para obtener una instancia del repositorio de novedades
  NovedadesRepository get novedadesRepository => NovedadesRepository();
  // Método para obtener una instancia del repositorio de batchs
  BatchPickingRepository get batchPickingRepository => BatchPickingRepository();
  // Método para obtener una instancia del repositorio de submuelles
  SubmuellesRepository get submuellesRepository => SubmuellesRepository();
  //metodo  para obtener una instancia del repositorio de URLs recientes
  UrlsRecientesRepository get urlsRecientesRepository =>
      UrlsRecientesRepository();
  //metodo  para obtener una instancia del repositorio de configuraciones
  ConfigurationsRepository get configurationsRepository =>
      ConfigurationsRepository();
  //metodo  para obtener una instancia del repositorio de pedidos packing
  PedidosPackingRepository get pedidosPackingRepository =>
      PedidosPackingRepository();
  //metodo  para obtener una instancia del repositorio de paquetes
  PackagesRepository get packagesRepository => PackagesRepository();
  //metodo  para obtener una instancia del repositorio de barcodes
  BarcodesRepository get barcodesPackagesRepository => BarcodesRepository();
  //metodo  para obtener una instancia del repositorio de productos de un pedido
  ProductosPedidosRepository get productosPedidosRepository =>
      ProductosPedidosRepository();
  //metodo  para obtener una instancia del repositorio de batchs para packing
  BatchPackingRepository get batchPackingRepository => BatchPackingRepository();
  //metodo  para obtener una instancia del repositorio de productos de entradas de recepcion
  ProductsEntradaRepository get productEntradaRepository =>
      ProductsEntradaRepository();
  //metodo  para obtener una instancia del repositorio  de entradas de recepcion
  EntradasRepository get entradasRepository => EntradasRepository();
  //metodo  para obtener una instancia del repositorio  de transferencias
  TransferenciaRepository get transferenciaRepository =>
      TransferenciaRepository();
  //metodo  para obtener una instancia del repositorio  de prodcutos de una transferencia
  ProductTransferenciaRepository get productTransferenciaRepository =>
      ProductTransferenciaRepository();
  //metodo  para obtener una instancia del repositorio  de ubicaciones
  UbicacionesRepository get ubicacionesRepository => UbicacionesRepository();

  //metodo  para obtener una instancia del repositorio  de barcodes de inventario
  BarcodesInventarioRepository get barcodesInventarioRepository =>
      BarcodesInventarioRepository();

  //metodo  para obtener una instancia del repositorio  de productos de inventario
  ProductInventarioRepository get productoInventarioRepository =>
      ProductInventarioRepository();

  WarehouseRepository get warehouseRepository => WarehouseRepository();

  DocOriginRepository get docOriginRepository => DocOriginRepository();

  //metodo  para obtener una instancia del repositorio  de picking por pick
  PickingPickRepository get pickRepository => PickingPickRepository();

  PickProductsRepository get pickProductsRepository => PickProductsRepository();
  //metodo para obtener una instancia del repositorio de entrada por batch
  EntradaBatchRepository get entradaBatchRepository => EntradaBatchRepository();
  //metodo pra obtener una instancia del repositorio de productos de recepcion por batch
  ProductsEntradaBatchRepository get productsEntradaBatchRepository =>
      ProductsEntradaBatchRepository();

//metodo para onteer una instancia del repositorio de packig por pedido
  PedidoPackRepository get pedidoPackRepository =>
      PedidoPackRepository(_instance);

  ProductDevolucionRepository get devolucionRepository =>
      ProductDevolucionRepository(_instance);

  OrdenConteoRepository get ordenRepository => OrdenConteoRepository();

  ProductoOrdenConteoRepository get productoOrdenConteoRepository =>
      ProductoOrdenConteoRepository();

  UbicacionesConteoRepository get ubicacionesConteoRepository =>
      UbicacionesConteoRepository();

  CategoriasConteoRepository get categoriasConteoRepository =>
      CategoriasConteoRepository();

  //repositorio de productos para crear transferencia
  ProductCreateTransferRepository get productCreateTransferRepository =>
      ProductCreateTransferRepository();

  //repositorio de pedidos de packing consolidade
  PedidosPackingConsolidateRepository get pedidosPackingConsolidateRepository =>
      PedidosPackingConsolidateRepository();

  //repositorio de batchs de packing consolidade
  BatchPackingConsolidateRepository get batchPackingConsolidateRepository =>
      BatchPackingConsolidateRepository();

  Future<Database> getDatabaseInstance() async {
    if (_database != null) {
      return _database!; // Si la base de datos ya está abierta, retornarla
    }
    _database = await initDB(); // Intenta abrir la base de datos
    return _database!;
  }

  //Todo: Métodos para batchs_products

  Future<void> insertBatchProducts(
      List<ProductsBatch> productsBatchList, String type) async {
    try {
      final db = await getDatabaseInstance();
      if (db == null) return;

      await db.transaction((txn) async {
        final batch = txn.batch();

        // Obtener todos los registros existentes una sola vez
        final existing = await txn.query('tblbatch_products');
        final existingSet = existing
            .map((e) => '${e['id_product']}_${e['batch_id']}_${e['id_move']}')
            .toSet();

        for (var product in productsBatchList) {
          final key =
              '${product.idProduct}_${product.batchId}_${product.idMove}';

          final data = {
            "id_product": product.idProduct,
            "type": type,
            "batch_id": product.batchId,
            "expire_date":
                product.expireDate == false ? "" : product.expireDate,
            "product_id": product.productId?[1],
            "location_id": product.locationId?[1],
            "lot_id": product.lotId == "" ? "" : product.lotId?[1],
            "rimoval_priority": product.rimovalPriority,
            "barcode_location_dest": product.barcodeLocationDest == false
                ? ""
                : product.barcodeLocationDest,
            "barcode_location":
                product.barcodeLocation == false ? "" : product.barcodeLocation,
            "lote_id": product.loteId,
            "id_move": product.idMove,
            "location_dest_id": product.locationDestId?[1],
            "id_location_dest": product.locationDestId?[0],
            "quantity": product.quantity,
            "unidades": product.unidades,
            "muelle_id": product.locationDestId?[0],
            "barcode": product.barcode == false ? "" : product.barcode,
            "weight": product.weigth,
            "origin": product.origin,
            "is_separate": product.isSeparate.toString(),
            //si el producto esta separado en la hora de insertarlo quiere decir que ya esta en el wms (odoo)
            "is_send_odoo": product.isSeparate == 0 ? null : product.isSeparate,
            "time_separate": _parseDurationToSeconds(product.timeSeparate),

            "observation":
                product.observation == false ? "" : product.observation,
            "quantity_separate": product.quantitySeparate,
            'fecha_transaccion': product.fechaTransaccion == false
                ? ""
                : product.fechaTransaccion,
          };

          if (existingSet.contains(key)) {
            // Actualizar si ya existe
            batch.update(
              'tblbatch_products',
              data,
              where: 'id_product = ? AND batch_id = ? AND id_move = ?',
              whereArgs: [
                product.idProduct,
                product.batchId,
                product.idMove,
              ],
            );
          } else {
            // Insertar si no existe
            batch.insert(
              'tblbatch_products',
              data,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        await batch.commit(noResult: true); // Mejor rendimiento
      });
    } catch (e, s) {
      print('Error insertBatchProducts: $e => $s');
    }
  }

  double? _parseDurationToSeconds(dynamic time) {
    try {
      if (time is String && time.contains(':')) {
        final parts = time.split(':').map(int.parse).toList();
        if (parts.length == 3) {
          final duration = Duration(
            hours: parts[0],
            minutes: parts[1],
            seconds: parts[2],
          );
          return duration.inSeconds.toDouble();
        }
      }
    } catch (e) {
      print('Error parsing time_separate: $e');
    }
    return null; // Si no es válido, devuelve null
  }

  //metodo para traer un producto de un batch de la tabla tblbatch_products
  Future<ProductsBatch?> getProductBatch(
      int batchId, int productId, int idMove, String type) async {
    final db = await getDatabaseInstance();
    final List<Map<String, dynamic>> maps = await db!.query(
      'tblbatch_products',
      where: 'batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
      whereArgs: [batchId, productId, idMove, type],
    );

    if (maps.isNotEmpty) {
      return ProductsBatch.fromMap(maps.first);
    }
    return null;
  }

  //* Obtener todos los productos de tblbatch_products
  Future<List<ProductsBatch>> getProducts(String type) async {
    final db = await getDatabaseInstance();
    final List<Map<String, dynamic>> maps = await db!
        .query('tblbatch_products', where: 'type = ?', whereArgs: [type]);
    return maps.map((map) => ProductsBatch.fromMap(map)).toList();
  }

  //* Obtener un batch con sus productos
  Future<BatchWithProducts?> getBatchWithProducts(
      int batchId, String type) async {
    try {
      final db = await getDatabaseInstance();
      final List<Map<String, dynamic>> batchMaps = await db!.query(
        'tblbatchs',
        where: 'id = ?',
        whereArgs: [batchId],
      );
      if (batchMaps.isEmpty) {
        return null; // No se encontró el batch
      }

      final BatchsModel batch = BatchsModel.fromMap(batchMaps.first);
      final List<Map<String, dynamic>> productMaps = await db.query(
        'tblbatch_products',
        where: 'batch_id = ? AND type = ?',
        whereArgs: [batchId, type],
      );
      final List<ProductsBatch> products =
          productMaps.map((map) => ProductsBatch.fromMap(map)).toList();

      return BatchWithProducts(batch: batch, products: products);
    } catch (e, s) {
      print('Error getBatchWithProducts: $e => $s');
    }
    return null;
  }
  //* Obtener un batch con sus productos

  //Todo: Eliminar todos los registros

  //metodo para eliminar lo de conteo
  Future<void> deleConteo() async {
    final db = await getDatabaseInstance();
    await db.delete(OrdenTable.tableName);
    await db.delete(ProductosOrdenConteoTable.tableName);
    await db.delete(CategoriasConteoTable.tableName);
    await db.delete(UbicacionesConteoTable.tableName);
    await deleBarcodes("orden");
  }

  Future<void> deleAllPicking() async {
    final db = await getDatabaseInstance();
    await db.delete(BatchPickingTable.tableName);
    await db.delete('tblbatch_products');
    await db.delete(SubmuellesTable.tableName);
    await deleOrigin("picking");
    await deleOrigin("components");
  }

  Future<void> delePicking(String type) async {
    final db = await getDatabaseInstance();
    await db.delete(BatchPickingTable.tableName,
        where: '${BatchPickingTable.columnType} = ?', whereArgs: [type]);
    await db.delete('tblbatch_products', where: 'type = ?', whereArgs: [type]);
    await deleBarcodes(type);
    await db.delete(SubmuellesTable.tableName);
    await deleOrigin(type);
  }

  Future<void> delePick(String typPick) async {
    final db = await getDatabaseInstance();
    await db.delete(PickingPickTable.tableName,
        where: '${PickingPickTable.columnTypePick} = ?', whereArgs: [typPick]);
    await db.delete(PickProductsTable.tableName,
        where: '${PickProductsTable.columnTypePick} = ?', whereArgs: [typPick]);
    await deleBarcodes(typPick);
  }

  Future<void> delePickAll() async {
    final db = await getDatabaseInstance();
    await db.delete(PickingPickTable.tableName);
    await db.delete(PickProductsTable.tableName);
    await deleBarcodes("pick");
    await deleBarcodes("picking");
  }

  Future<void> deleReceptionBatch() async {
    final db = await getDatabaseInstance();
    await db.delete(EntradaBatchTable.tableName);
    await db.delete(ProductRecepcionBatchTable.tableName);
    await deleBarcodes("reception-batch");
  }

  Future<void> delePacking(String type) async {
    final db = await getDatabaseInstance();
    if (type == "packing-batch") {
      await deleOrigin("packing");
      await db.delete(BatchPackingTable.tableName);
    }
    if (type == "packing-pack") {
      await db.delete(PedidoPackTable.tableName);
    }
    if (type == "packing-batch-consolidate-") {
      await db.delete(BatchPackingConsolidateTable.tableName);
      await db.delete(PedidosPackingConsolidateTable.tableName);
    }

    await db.delete(PedidosPackingTable.tableName,
        where: '${PedidosPackingTable.columnType} = ?', whereArgs: [type]);
    await db.delete(ProductosPedidosTable.tableName,
        where: '${ProductosPedidosTable.columnType} = ?', whereArgs: [type]);
    await db.delete(PackagesTable.tableName,
        where: '${PackagesTable.columnType} = ?', whereArgs: [type]);
    await deleBarcodes(type);
  }

  Future<void> delePackingAll() async {
    final db = await getDatabaseInstance();
    await db.delete(BatchPackingTable.tableName);
    await db.delete(PedidosPackingTable.tableName);
    await db.delete(ProductosPedidosTable.tableName);
    await db.delete(PackagesTable.tableName);
    await deleBarcodes("packing-batch");
    await deleBarcodes("packing");
  }

  Future<void> deleRecepcion(String type) async {
    final db = await getDatabaseInstance();
    await db.delete(
      ProductRecepcionTable.tableName,
      where: '${ProductRecepcionTable.columnType} = ?',
      whereArgs: [type],
    );
    await db.delete(
      EntradasRepeccionTable.tableName,
      where: '${EntradasRepeccionTable.columnType} = ?',
      whereArgs: [type],
    );
    await deleBarcodes("reception");
  }

  Future<void> deleInventario() async {
    final db = await getDatabaseInstance();
    await db.delete(ProductInventarioTable.tableName);
    await db.delete(BarcodesInventarioTable.tableName);
  }

  Future<void> deleTrasnferencia(String type) async {
    final db = await getDatabaseInstance();
    //transferencia
    await db.delete(
      TransferenciaTable.tableName,
      where: '${TransferenciaTable.columnType} = ?',
      whereArgs: [type],
    );
    await db.delete(
      ProductTransferenciaTable.tableName,
      where: '${ProductTransferenciaTable.columnType} = ?',
      whereArgs: [type],
    );
    await deleBarcodes("transfer");
  }

  Future<void> deleAllTrasnferencia() async {
    final db = await getDatabaseInstance();
    //transferencia
    await db.delete(
      TransferenciaTable.tableName,
    );
    await db.delete(
      ProductTransferenciaTable.tableName,
    );
    await deleBarcodes("transfer");
  }

  Future<void> deleOthers() async {
    final db = await getDatabaseInstance();
    await db.delete(ConfigurationsTable.tableName);
    await db.delete(NovedadesTable.tableName);
    await db.delete(UbicacionesTable.tableName);
    await db.delete(WarehouseTable.tableName);
  }

  Future<void> deleBarcodes(String barcodeType) async {
    final db = await getDatabaseInstance();
    //eliminamos los codigos de barras que tienen el mismo tipo
    await db.delete(BarcodesPackagesTable.tableName,
        where: '${BarcodesPackagesTable.columnBarcodeType} = ?',
        whereArgs: [barcodeType]);
  }

  Future<void> deleOrigin(String originType) async {
    final db = await getDatabaseInstance();
    //eliminamos los codigos de barras que tienen el mismo tipo
    await db.delete(DocOriginTable.tableName,
        where: '${DocOriginTable.columnOriginType} = ?',
        whereArgs: [originType]);
  }

  Future<void> deleAllBarcodes() async {
    final db = await getDatabaseInstance();
    //eliminamos todos los codigos de barras
    await db.delete(BarcodesPackagesTable.tableName);
  }

  Future<void> deleAllRecepcion() async {
    final db = await getDatabaseInstance();
    await db.delete(
      ProductRecepcionTable.tableName,
    );
    await db.delete(
      EntradasRepeccionTable.tableName,
    );
    await deleBarcodes("reception");
  }

  Future<void> deleteBDCloseSession() async {
    await deleAllPicking();
    await delePickAll();
    await delePackingAll();
    await deleAllRecepcion();
    await deleAllTrasnferencia();
    await deleInventario();
    await deleOthers();
    await deleReceptionBatch();
    await deleAllBarcodes();
    await deleConteo();
  }

  //*metodo para actualizar la tabla de productos de un batch
 Future<int?> setFieldTableBatchProducts(int batchId, int productId,
      String field, dynamic setValue, int idMove, String type) async {
    final db = await getDatabaseInstance();
    
    // ✅ SOLUCIÓN: Usamos '?' para los valores y pasamos una lista de argumentos.
    // Nota: $field se deja igual porque es el nombre de la columna, no un valor.
    final resUpdate = await db!.rawUpdate(
        'UPDATE tblbatch_products SET $field = ? WHERE batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
        [setValue, batchId, productId, idMove, type]); // <--- Aquí pasamos la lista
        
    print("update tblbatch_products ($field): $resUpdate");

    return resUpdate;
  }


  // ✅ 1. Método genérico para actualizar un campo string
  // Usamos db.update para manejar automáticamente los tipos de datos
  Future<int?> setFieldStringTableBatchProducts(int batchId, int productId,
      String field, dynamic setValue, int idMove, String type) async {
    final db = await getDatabaseInstance();
    
    // db.update es mejor que rawUpdate porque maneja las comillas automáticamente
    return await db!.update(
      'tblbatch_products',
      {field: setValue}, // Mapa: columna -> valor
      where: 'batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
      whereArgs: [batchId, productId, idMove, type],
    );
  }

  // ✅ 2. Obtener un campo específico
  Future<String> getFieldTableProducts(
      int batchId, int productId, int moveId, String field, String type) async {
    try {
      final db = await getDatabaseInstance();
      
      final res = await db!.query(
        'tblbatch_products',
        columns: [field],
        where: 'batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
        whereArgs: [batchId, productId, moveId, type],
        limit: 1,
      );

      if (res.isNotEmpty) {
        return res.first[field].toString();
      }
      return "";
    } catch (e, s) {
      print("error getFieldTableProducts: $e => $s");
      return "";
    }
  }

  // --- MÉTODOS PARA EL PICKING (Stopwatch y Novedades) ---

  // ✅ 3. Iniciar cronómetro
  Future<int?> startStopwatch(
      int batchId, int productId, int moveId, String date, String type) async {
    final db = await getDatabaseInstance();
    
    return await db!.update(
      'tblbatch_products',
      {'time_separate_start': date},
      where: 'batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
      whereArgs: [batchId, productId, moveId, type],
    );
  }

  // ✅ 4. Guardar tiempo total
  Future<int?> totalStopwatchProduct(
      int batchId, int productId, int moveId, double time, String type) async {
    final db = await getDatabaseInstance();
    
    return await db!.update(
      'tblbatch_products',
      {'time_separate': time},
      where: 'batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
      whereArgs: [batchId, productId, moveId, type],
    );
  }

  // ✅ 5. Finalizar cronómetro
  Future<int?> endStopwatchProduct(
      int batchId, String date, int productId, int moveId, String type) async {
    final db = await getDatabaseInstance();
    
    return await db!.update(
      'tblbatch_products',
      {'time_separate_end': date},
      where: 'batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
      whereArgs: [batchId, productId, moveId, type],
    );
  }

  // ✅ 6. Actualizar fecha transacción
  Future<int?> dateTransaccionProduct(
      int batchId, String date, int productId, int moveId, String type) async {
    final db = await getDatabaseInstance();
    
    return await db!.update(
      'tblbatch_products',
      {'fecha_transaccion': date},
      where: 'batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
      whereArgs: [batchId, productId, moveId, type],
    );
  }

  // ✅ 7. Actualizar novedad u observación
  Future<int?> updateNovedad(
    int batchId,
    int productId,
    String novedad,
    int idMove,
    String type,
  ) async {
    final db = await getDatabaseInstance();
    
    return await db!.update(
      'tblbatch_products',
      {'observation': novedad},
      where: 'batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
      whereArgs: [batchId, productId, idMove, type],
    );
  }

  // --- MÉTODOS DE INCREMENTO (Estos ya estaban bien, solo retoques) ---

  // ✅ 8. Incrementar cantidad separada en Batch
  Future<int?> incrementProductSeparateQty(int batchId, String type) async {
    final db = await getDatabaseInstance();

    return await db!.transaction((txn) async {
      final result = await txn.query(
        'tblbatchs',
        columns: ['product_separate_qty'],
        where: 'id = ? AND type = ?',
        whereArgs: [batchId, type],
      );

      if (result.isNotEmpty) {
        dynamic currentQty = (result.first['product_separate_qty']) ?? 0;
        dynamic newQty = currentQty + 1;

        return await txn.update(
          'tblbatchs',
          {'product_separate_qty': newQty},
          where: 'id = ?',
          whereArgs: [batchId], // Aquí type no es estrictamente necesario si ID es único, pero no hace daño
        );
      }
      return null;
    });
  }

  // ✅ 9. Incrementar cantidad separada en Producto
  Future<int?> incremenQtytProductSeparate(int batchId, int productId,
      int idMove, dynamic quantity, String type) async {
    final db = await getDatabaseInstance();
    
    return await db!.transaction((txn) async {
      final result = await txn.query(
        'tblbatch_products',
        columns: ['quantity_separate', 'quantity'],
        where: 'batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
        whereArgs: [batchId, productId, idMove, type],
      );

      if (result.isNotEmpty) {
        // Aseguramos que los números sean tratados como num (int o double)
        num currentQtySeparate = (result.first['quantity_separate'] as num?) ?? 0;
        num currentQty = (result.first['quantity'] as num?) ?? 0;

        num newQtySeparate = currentQtySeparate + (quantity as num);

        if (newQtySeparate > currentQty) {
          newQtySeparate = currentQty;
        }

        // CORRECCIÓN: Agregué 'type' al whereArgs del update para ser consistentes
        return await txn.update(
          'tblbatch_products',
          {'quantity_separate': newQtySeparate},
          where: 'batch_id = ? AND id_product = ? AND id_move = ? AND type = ?',
          whereArgs: [batchId, productId, idMove, type], 
        );
      }
      return null;
    });
  }

  // --- MÉTODOS DE OBTENCIÓN DE DATOS COMPLETOS ---

  // ✅ 10. Get Producto Batch
  Future<List<Map<String, dynamic>>> getProductBacth(
    int batchId,
    int productId,
    String type,
  ) async {
    final db = await getDatabaseInstance();

    return await db!.query(
      'tblbatch_products',
      where: 'batch_id = ? AND id_product = ? AND type = ?',
      whereArgs: [batchId, productId, type],
      limit: 1,
    );
  }

  // ✅ 11. Get Batch
  Future<List<Map<String, dynamic>>> getBacth(
    int batchId,
    String type,
  ) async {
    final db = await getDatabaseInstance();

    return await db!.query(
      'tblbatchs',
      where: 'id = ? AND type = ?',
      whereArgs: [batchId, type],
      limit: 1,
    );
  }

}
