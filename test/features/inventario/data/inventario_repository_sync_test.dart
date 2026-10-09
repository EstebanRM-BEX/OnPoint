import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/inventario/data/datasources/inventario_local_data_source.dart';
import 'package:wms_app/features/inventario/data/datasources/inventario_remote_data_source.dart';
import 'package:wms_app/features/inventario/data/models/producto_inventario_model.dart';
import 'package:wms_app/features/inventario/data/repositories/inventario_repository_impl.dart';

class _Remote extends Mock implements InventarioRemoteDataSource {}

class _Local extends Mock implements InventarioLocalDataSource {}

class _Red extends Mock implements NetworkInfo {}

void main() {
  late _Remote remote;
  late _Local local;
  late InventarioRepositoryImpl repo;

  const empresa = 'https://cliente.com|bd';
  const producto = ProductoInventarioModel(productId: 1, name: 'P');
  const marca = (since: '2026-10-09 15:00:00', scope: 'abc');

  void respuesta(ProductosSyncResult r) => when(
    () => remote.syncProductos(
      since: any(named: 'since'),
      scope: any(named: 'scope'),
    ),
  ).thenAnswer((_) async => r);

  setUp(() {
    remote = _Remote();
    local = _Local();
    final red = _Red();
    when(() => red.isConnected).thenAnswer((_) async => true);
    when(() => local.empresaActual()).thenAnswer((_) async => empresa);
    when(() => local.empresaCatalogo()).thenAnswer((_) async => empresa);
    when(() => local.marcaSyncCatalogo()).thenAnswer((_) async => null);
    when(() => local.getProductosCount()).thenAnswer((_) async => 10);
    when(() => local.deleteInventario()).thenAnswer((_) async {});
    when(() => local.reemplazarCatalogo(any(), any())).thenAnswer((_) async {});
    when(
      () => local.aplicarCambiosCatalogo(
        productos: any(named: 'productos'),
        barcodes: any(named: 'barcodes'),
        eliminados: any(named: 'eliminados'),
        activos: any(named: 'activos'),
      ),
    ).thenAnswer((_) async {});
    when(() => local.guardarEmpresaCatalogo(any())).thenAnswer((_) async {});
    when(() => local.guardarMarcaSyncCatalogo(any(), any()))
        .thenAnswer((_) async {});
    when(() => local.borrarMarcaSyncCatalogo()).thenAnswer((_) async {});
    repo = InventarioRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: red,
    );
  });

  test('si la descarga falla, el catálogo y la marca quedan intactos', () async {
    when(() => local.marcaSyncCatalogo()).thenAnswer((_) async => marca);
    when(
      () => remote.syncProductos(
        since: any(named: 'since'),
        scope: any(named: 'scope'),
      ),
    ).thenThrow(const ServerException('timeout'));

    final r = await repo.syncProductosInventario(false);

    expect(r.isLeft(), isTrue);
    verifyNever(() => local.deleteInventario());
    verifyNever(() => local.reemplazarCatalogo(any(), any()));
    verifyNever(() => local.guardarMarcaSyncCatalogo(any(), any()));
    verifyNever(() => local.borrarMarcaSyncCatalogo());
  });

  test('completa sin productos no reemplaza el catálogo', () async {
    respuesta(const ProductosSyncResult(productos: [], barcodes: []));

    final r = await repo.syncProductosInventario(false);

    expect(r.getLeft().toNullable(), isA<ServerFailure>());
    verifyNever(() => local.reemplazarCatalogo(any(), any()));
  });

  test('sin marca pide completo, reemplaza y guarda la marca nueva', () async {
    respuesta(const ProductosSyncResult(
      productos: [producto],
      barcodes: [],
      serverTime: '2026-10-09 16:00:00',
      scope: 'abc',
    ));

    final r = await repo.syncProductosInventario(false);

    expect(r.isRight(), isTrue);
    verify(() => remote.syncProductos(since: null, scope: null)).called(1);
    verify(() => local.reemplazarCatalogo([producto], [])).called(1);
    verify(() => local.guardarEmpresaCatalogo(empresa)).called(1);
    verify(() => local.guardarMarcaSyncCatalogo('2026-10-09 16:00:00', 'abc'))
        .called(1);
  });

  test('con marca pide incremental y aplica los cambios', () async {
    when(() => local.marcaSyncCatalogo()).thenAnswer((_) async => marca);
    respuesta(const ProductosSyncResult(
      productos: [producto],
      barcodes: [],
      full: false,
      serverTime: '2026-10-09 16:00:00',
      scope: 'abc',
      deletedProductIds: [9],
      activeProductIds: [1],
    ));

    await repo.syncProductosInventario(false);

    verify(() => remote.syncProductos(since: marca.since, scope: marca.scope))
        .called(1);
    verify(
      () => local.aplicarCambiosCatalogo(
        productos: [producto],
        barcodes: [],
        eliminados: [9],
        activos: [1],
      ),
    ).called(1);
    verifyNever(() => local.reemplazarCatalogo(any(), any()));
  });

  test('incremental sin cambios no es un error', () async {
    when(() => local.marcaSyncCatalogo()).thenAnswer((_) async => marca);
    respuesta(const ProductosSyncResult(
      productos: [],
      barcodes: [],
      full: false,
      serverTime: '2026-10-09 16:00:00',
      scope: 'abc',
    ));

    expect((await repo.syncProductosInventario(false)).isRight(), isTrue);
  });

  test('catálogo local vacío ignora la marca y pide completo', () async {
    when(() => local.marcaSyncCatalogo()).thenAnswer((_) async => marca);
    when(() => local.getProductosCount()).thenAnswer((_) async => 0);
    respuesta(const ProductosSyncResult(productos: [producto], barcodes: []));

    await repo.syncProductosInventario(false);

    verify(() => remote.syncProductos(since: null, scope: null)).called(1);
  });

  test('backend anterior (sin server_time) borra la marca', () async {
    respuesta(const ProductosSyncResult(productos: [producto], barcodes: []));

    await repo.syncProductosInventario(false);

    verify(() => local.borrarMarcaSyncCatalogo()).called(1);
    verifyNever(() => local.guardarMarcaSyncCatalogo(any(), any()));
  });

  test('catálogo de otra empresa: se borra con su marca antes de descargar',
      () async {
    when(() => local.empresaCatalogo()).thenAnswer((_) async => null);
    when(
      () => remote.syncProductos(
        since: any(named: 'since'),
        scope: any(named: 'scope'),
      ),
    ).thenThrow(const ServerException('x'));

    await repo.syncProductosInventario(false);

    verify(() => local.deleteInventario()).called(1);
    verify(() => local.borrarMarcaSyncCatalogo()).called(1);
  });
}
