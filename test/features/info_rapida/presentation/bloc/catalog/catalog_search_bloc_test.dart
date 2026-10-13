import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/buscar_catalogo_productos_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/buscar_catalogo_ubicaciones_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_almacenes_ubicaciones_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_propietarios_catalogo_usecase.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/catalog/catalog_search_bloc.dart';

class MockBuscarCatalogoProductosUseCase extends Mock
    implements BuscarCatalogoProductosUseCase {}

class MockGetPropietariosCatalogoUseCase extends Mock
    implements GetPropietariosCatalogoUseCase {}

class MockBuscarCatalogoUbicacionesUseCase extends Mock
    implements BuscarCatalogoUbicacionesUseCase {}

class MockGetAlmacenesUbicacionesUseCase extends Mock
    implements GetAlmacenesUbicacionesUseCase {}

void main() {
  late MockBuscarCatalogoProductosUseCase mockBuscarProductos;
  late MockGetPropietariosCatalogoUseCase mockGetPropietarios;
  late MockBuscarCatalogoUbicacionesUseCase mockBuscarUbicaciones;
  late MockGetAlmacenesUbicacionesUseCase mockGetAlmacenes;

  final tProducto1 = const ProductoCatalogo(
    id: 1,
    name: 'Tornillo Hexagonal',
    code: 'TOR-001',
    barcode: '7701001',
    otherBarcodes: ['ALT-001'],
    lotName: 'LOT-A',
    quantity: 100,
  );

  final tProducto2 = const ProductoCatalogo(
    id: 2,
    name: 'Tuerca Autofrenante',
    code: 'TUE-002',
    barcode: '7701002',
    otherBarcodes: ['ALT-002'],
    lotName: 'LOT-B',
    quantity: 50,
  );

  final tProducto3 = const ProductoCatalogo(
    id: 3,
    name: 'Arandela de Presión',
    code: 'ARA-003',
    barcode: '7701003',
    otherBarcodes: ['EXTRA-999'],
    lotName: 'LOT-C',
    quantity: 200,
  );

  final tUbicacion1 = const UbicacionCatalogo(
    id: 10,
    name: 'WH/Stock/A1',
    barcode: 'LOC-A1',
    idWarehouse: 1,
    warehouseName: 'Almacén Central',
  );

  final tUbicacion2 = const UbicacionCatalogo(
    id: 20,
    name: 'WH/Stock/B1',
    barcode: 'LOC-B1',
    idWarehouse: 1,
    warehouseName: 'Almacén Central',
  );

  final tUbicacion3 = const UbicacionCatalogo(
    id: 30,
    name: 'REP/Stock/R1',
    barcode: 'LOC-R1',
    idWarehouse: 2,
    warehouseName: 'Almacén Repuestos',
  );

  setUpAll(() {
    registerFallbackValue(const BuscarCatalogoProductosParams(limit: 1));
    registerFallbackValue(NoParams());
    registerFallbackValue(const BuscarCatalogoUbicacionesParams(limit: 1));
  });

  setUp(() {
    mockBuscarProductos = MockBuscarCatalogoProductosUseCase();
    mockGetPropietarios = MockGetPropietariosCatalogoUseCase();
    when(() => mockGetPropietarios(any()))
        .thenAnswer((_) async => const Right(['ACME', 'Otro']));
    mockBuscarUbicaciones = MockBuscarCatalogoUbicacionesUseCase();
    mockGetAlmacenes = MockGetAlmacenesUbicacionesUseCase();
    when(() => mockGetAlmacenes(any())).thenAnswer(
      (_) async => const Right(['Almacén Central', 'Almacén Repuestos']),
    );
  });

  CatalogSearchBloc buildBloc() => CatalogSearchBloc(
        buscarCatalogoProductos: mockBuscarProductos,
        getPropietariosCatalogo: mockGetPropietarios,
        buscarCatalogoUbicaciones: mockBuscarUbicaciones,
        getAlmacenesUbicaciones: mockGetAlmacenes,
      );

  group('CatalogSearchBloc', () {
    test('estado inicial correcto', () {
      final bloc = buildBloc();
      expect(bloc.state.statusProductos, equals(CatalogStatus.initial));
      expect(bloc.state.statusUbicaciones, equals(CatalogStatus.initial));
      expect(bloc.state.hayMasProductos, isFalse);
      expect(bloc.state.propietarioProducto, isNull);
      expect(bloc.state.productosFiltrados, isEmpty);
      expect(bloc.state.ubicacionesFiltradas, isEmpty);
      expect(bloc.state.hayMasUbicaciones, isFalse);
      expect(bloc.state.queryProducto, isEmpty);
      expect(bloc.state.queryUbicacion, isEmpty);
      expect(bloc.state.almacenUbicacionesFiltro, isNull);
      expect(bloc.state.almacenesDisponibles, isEmpty);
    });

    group('productos (consulta paginada)', () {
      const pagina = CatalogSearchBloc.paginaProductos;
      final paginaLlena = List.generate(
        pagina,
        (i) => ProductoCatalogo(id: i + 1, name: 'P${i + 1}'),
      );

      BuscarCatalogoProductosParams params(int n) =>
          verify(() => mockBuscarProductos(captureAny())).captured[n]
              as BuscarCatalogoProductosParams;

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'cargar trae la primera página y los propietarios',
        build: () {
          when(() => mockBuscarProductos(any())).thenAnswer(
            (_) async => Right([tProducto1, tProducto2]),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CargarCatalogoProductosEvent()),
        expect: () => [
          CatalogSearchState(
            statusProductos: CatalogStatus.success,
            productosFiltrados: [tProducto1, tProducto2],
          ),
          CatalogSearchState(
            statusProductos: CatalogStatus.success,
            productosFiltrados: [tProducto1, tProducto2],
            propietarios: const ['ACME', 'Otro'],
          ),
        ],
        verify: (_) {
          final p = params(0);
          expect(p.query, '');
          expect(p.offset, 0);
          expect(p.limit, pagina);
        },
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'buscar consulta SQLite con el texto (no filtra en memoria)',
        build: () {
          when(() => mockBuscarProductos(any()))
              .thenAnswer((_) async => Right([tProducto1]));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const BuscarProductosCatalogoEvent('tornillo')),
        expect: () => [
          const CatalogSearchState(queryProducto: 'tornillo'),
          CatalogSearchState(
            statusProductos: CatalogStatus.success,
            queryProducto: 'tornillo',
            productosFiltrados: [tProducto1],
          ),
        ],
        verify: (_) => expect(params(0).query, 'tornillo'),
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'filtrar por propietario consulta con ese propietario',
        build: () {
          when(() => mockBuscarProductos(any()))
              .thenAnswer((_) async => Right([tProducto2]));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const FiltrarProductosPorPropietarioEvent('ACME')),
        verify: (bloc) {
          expect(params(0).propietario, 'ACME');
          expect(bloc.state.propietarioProducto, 'ACME');
          expect(bloc.state.productosFiltrados, [tProducto2]);
        },
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'página llena habilita cargar más; la siguiente se agrega al final',
        build: () {
          var llamada = 0;
          when(() => mockBuscarProductos(any())).thenAnswer((_) async {
            llamada++;
            return Right(llamada == 1 ? paginaLlena : [tProducto3]);
          });
          return buildBloc();
        },
        act: (bloc) async {
          bloc.add(const BuscarProductosCatalogoEvent('p'));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const CargarMasProductosCatalogoEvent());
        },
        verify: (bloc) {
          expect(params(1).offset, pagina);
          expect(bloc.state.productosFiltrados, [...paginaLlena, tProducto3]);
          expect(bloc.state.hayMasProductos, isFalse);
        },
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'sin más resultados no vuelve a consultar',
        build: buildBloc,
        seed: () => CatalogSearchState(productosFiltrados: [tProducto1]),
        act: (bloc) => bloc.add(const CargarMasProductosCatalogoEvent()),
        expect: () => const <CatalogSearchState>[],
        verify: (_) => verifyNever(() => mockBuscarProductos(any())),
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'emite fallo cuando la consulta falla',
        build: () {
          when(() => mockBuscarProductos(any())).thenAnswer(
            (_) async => const Left(SinConexionFailure('Error de base local')),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const BuscarProductosCatalogoEvent('x')),
        verify: (bloc) {
          expect(bloc.state.statusProductos, CatalogStatus.failure);
          expect(bloc.state.mensajeErrorProductos, 'Error de base local');
        },
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'emite loading si la consulta supera el umbral',
        build: () {
          when(() => mockBuscarProductos(any())).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            return Right([tProducto1]);
          });
          return buildBloc();
        },
        act: (bloc) => bloc.add(const BuscarProductosCatalogoEvent('t')),
        wait: const Duration(milliseconds: 400),
        expect: () => [
          const CatalogSearchState(queryProducto: 't'),
          const CatalogSearchState(
            queryProducto: 't',
            statusProductos: CatalogStatus.loading,
          ),
          CatalogSearchState(
            queryProducto: 't',
            statusProductos: CatalogStatus.success,
            productosFiltrados: [tProducto1],
          ),
        ],
      );
    });

    group('indicador de carga', () {
      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'ubicaciones: emite loading si la consulta supera el umbral',
        build: () {
          when(() => mockBuscarUbicaciones(any())).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            return Right([tUbicacion1]);
          });
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CargarCatalogoUbicacionesEvent()),
        wait: const Duration(milliseconds: 400),
        expect: () => [
          isA<CatalogSearchState>().having(
            (s) => s.almacenesDisponibles,
            'almacenes',
            ['Almacén Central', 'Almacén Repuestos'],
          ),
          isA<CatalogSearchState>().having(
            (s) => s.statusUbicaciones,
            'status',
            CatalogStatus.loading,
          ),
          isA<CatalogSearchState>()
              .having((s) => s.statusUbicaciones, 'status', CatalogStatus.success)
              .having((s) => s.ubicacionesFiltradas, 'ubicaciones', [tUbicacion1]),
        ],
      );
    });

    group('ubicaciones (consulta paginada)', () {
      const pagina = CatalogSearchBloc.paginaUbicaciones;

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'carga la primera página y los almacenes (de SQLite)',
        build: () {
          when(() => mockBuscarUbicaciones(any())).thenAnswer(
            (_) async => Right([tUbicacion3, tUbicacion1, tUbicacion2]),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CargarCatalogoUbicacionesEvent()),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(bloc.state.statusUbicaciones, CatalogStatus.success);
          expect(bloc.state.ubicacionesFiltradas,
              [tUbicacion3, tUbicacion1, tUbicacion2]);
          expect(bloc.state.hayMasUbicaciones, isFalse);
          expect(bloc.state.almacenesDisponibles,
              ['Almacén Central', 'Almacén Repuestos']);
          verify(() => mockBuscarUbicaciones(
                const BuscarCatalogoUbicacionesParams(limit: pagina),
              )).called(1);
        },
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'emite fallo cuando la consulta falla',
        build: () {
          when(() => mockBuscarUbicaciones(any())).thenAnswer(
            (_) async => const Left(SinConexionFailure('Fallo de red')),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CargarCatalogoUbicacionesEvent()),
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(bloc.state.statusUbicaciones, CatalogStatus.failure);
          expect(bloc.state.mensajeErrorUbicaciones, 'Fallo de red');
        },
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'buscar y filtrar por almacén consultan SQLite con ambos criterios',
        build: () {
          when(() => mockBuscarUbicaciones(any()))
              .thenAnswer((_) async => Right([tUbicacion3]));
          return buildBloc();
        },
        act: (bloc) async {
          bloc.add(const FiltrarUbicacionesPorAlmacenEvent('Almacén Repuestos'));
          await Future<void>.delayed(const Duration(milliseconds: 20));
          bloc.add(const BuscarUbicacionesCatalogoEvent('LOC-R'));
        },
        wait: const Duration(milliseconds: 50),
        verify: (bloc) {
          expect(bloc.state.queryUbicacion, 'LOC-R');
          expect(bloc.state.almacenUbicacionesFiltro, 'Almacén Repuestos');
          expect(bloc.state.ubicacionesFiltradas, [tUbicacion3]);
          verify(() => mockBuscarUbicaciones(
                const BuscarCatalogoUbicacionesParams(
                  query: 'LOC-R',
                  almacen: 'Almacén Repuestos',
                  limit: pagina,
                ),
              )).called(1);
        },
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'cargar más agrega la página siguiente',
        build: () {
          when(() => mockBuscarUbicaciones(any()))
              .thenAnswer((_) async => Right([tUbicacion3]));
          return buildBloc();
        },
        seed: () => CatalogSearchState(
          statusUbicaciones: CatalogStatus.success,
          ubicacionesFiltradas: List.filled(pagina, tUbicacion1),
          hayMasUbicaciones: true,
        ),
        act: (bloc) =>
            bloc.add(const CargarMasUbicacionesCatalogoEvent()),
        verify: (bloc) {
          expect(bloc.state.ubicacionesFiltradas, hasLength(pagina + 1));
          expect(bloc.state.hayMasUbicaciones, isFalse);
          verify(() => mockBuscarUbicaciones(
                const BuscarCatalogoUbicacionesParams(
                  limit: pagina,
                  offset: pagina,
                ),
              )).called(1);
        },
      );
    });
  });
}
