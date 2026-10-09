import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/services/productos_cache_service.dart';
import 'package:wms_app/core/services/ubicaciones_cache_service.dart';
import 'package:wms_app/features/info_rapida/data/datasources/info_rapida_local_data_source.dart';
import 'package:wms_app/features/info_rapida/data/services/info_rapida_entorno.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_barcode/barcodes_inventario_table.dart';
import 'package:wms_app/src/presentation/providers/db/inventario/tbl_product/product_inventario_table.dart';

class _MockEntorno extends Mock implements InfoRapidaEntorno {}

class _MockProductos extends Mock implements ProductosCacheService {}

class _MockUbicaciones extends Mock implements UbicacionesCacheService {}

class _MockConfiguracion extends Mock implements ConfiguracionCacheService {}

class _MockDb extends Mock implements DataBaseSqlite {}

void main() {
  late Database db;
  late InfoRapidaLocalDataSourceImpl dataSource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> producto(
    int rowId,
    int productId,
    String name, {
    String? code,
    String? barcode,
    int loc = 0,
    int manejo = 0,
    String propietario = '',
  }) => db.insert(ProductInventarioTable.tableName, {
    ProductInventarioTable.columnId: rowId,
    ProductInventarioTable.columnProductId: productId,
    ProductInventarioTable.columnProductName: name,
    ProductInventarioTable.columnProductCode: code,
    ProductInventarioTable.columnBarcode: barcode,
    ProductInventarioTable.columnLotId: 0,
    ProductInventarioTable.columnLocationId: loc,
    ProductInventarioTable.columnManejoPropietario: manejo,
    ProductInventarioTable.columnPropietario: propietario,
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (d, _) async {
        // createTable trae varias sentencias; se ejecutan una por una.
        for (final sql in [
          ProductInventarioTable.createTable(),
          BarcodesInventarioTable.createTable(),
        ]) {
          for (final s in sql.split(';')) {
            final limpio = s
                .split('\n')
                .where((l) => !l.trim().startsWith('--'))
                .join('\n')
                .trim();
            if (limpio.isNotEmpty) await d.execute(limpio);
          }
        }
      },
    );
    final dbMock = _MockDb();
    when(() => dbMock.getDatabaseInstance()).thenAnswer((_) async => db);
    dataSource = InfoRapidaLocalDataSourceImpl.test(
      _MockEntorno(),
      _MockProductos(),
      _MockUbicaciones(),
      _MockConfiguracion(),
      dbMock,
    );

    // El producto 1 está en dos ubicaciones: debe salir una sola vez.
    await producto(1, 1, 'Tornillo Hexagonal', code: 'TOR-001', loc: 5);
    await producto(2, 1, 'Tornillo Hexagonal', code: 'TOR-001', loc: 6);
    await producto(
      3,
      2,
      'Tuerca 50%_x',
      barcode: '7701002',
      manejo: 1,
      propietario: 'ACME',
    );
    await producto(4, 3, 'Arandela', manejo: 1, propietario: 'Otro');
    await producto(5, 4, 'Clavo', manejo: 0, propietario: 'Ignorado');
    await db.insert(BarcodesInventarioTable.tableName, {
      BarcodesInventarioTable.columnIdProduct: 3,
      BarcodesInventarioTable.columnBarcode: 'EXTRA-999',
      BarcodesInventarioTable.columnCantidad: 1,
    });
  });

  tearDown(() => db.close());

  Future<List<int>> buscar(
    String q, {
    String? propietario,
    int limit = 50,
    int offset = 0,
  }) async => [
    for (final p in await dataSource.buscarCatalogoProductos(
      query: q,
      propietario: propietario,
      limit: limit,
      offset: offset,
    ))
      p.id,
  ];

  group('buscarCatalogoProductos', () {
    test('sin texto trae un producto por id, aunque tenga varias filas', () async {
      expect(await buscar(''), [1, 2, 3, 4]);
    });

    test('nombre, código y barcode sin distinguir mayúsculas', () async {
      expect(await buscar('TORNILLO'), [1]);
      expect(await buscar('tor-0'), [1]);
      expect(await buscar('7701002'), [2]);
    });

    test('barcode alterno', () async {
      expect(await buscar('extra-9'), [3]);
    });

    test('% y _ se buscan literales', () async {
      expect(await buscar('50%_'), [2]);
      expect(await buscar('_'), [2]);
    });

    test('filtra por propietario solo si maneja propietario', () async {
      expect(await buscar('', propietario: 'ACME'), [2]);
      expect(await buscar('', propietario: 'Ignorado'), isEmpty);
    });

    test('pagina con limit/offset', () async {
      expect(await buscar('', limit: 3), [1, 2, 3]);
      expect(await buscar('', limit: 3, offset: 3), [4]);
    });
  });

  test('getPropietariosCatalogo: distintos y ordenados', () async {
    expect(await dataSource.getPropietariosCatalogo(), ['ACME', 'Otro']);
  });
}
