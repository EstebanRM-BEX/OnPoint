import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/buscar_catalogo_productos_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_ubicaciones_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_propietarios_catalogo_usecase.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/catalog/catalog_search_bloc.dart';

class MockBuscarCatalogoProductosUseCase extends Mock
    implements BuscarCatalogoProductosUseCase {}

class MockGetPropietariosCatalogoUseCase extends Mock
    implements GetPropietariosCatalogoUseCase {}

class MockGetCatalogoUbicacionesUseCase extends Mock
    implements GetCatalogoUbicacionesUseCase {}

void main() {
  late MockBuscarCatalogoProductosUseCase mockBuscarProductos;
  late MockGetPropietariosCatalogoUseCase mockGetPropietarios;
  late MockGetCatalogoUbicacionesUseCase mockGetCatalogoUbicaciones;

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
    registerFallbackValue(
      const GetCatalogoUbicacionesParams(),
    );
  });

  setUp(() {
    mockBuscarProductos = MockBuscarCatalogoProductosUseCase();
    mockGetPropietarios = MockGetPropietariosCatalogoUseCase();
    when(() => mockGetPropietarios(any()))
        .thenAnswer((_) async => const Right(['ACME', 'Otro']));
    mockGetCatalogoUbicaciones = MockGetCatalogoUbicacionesUseCase();
  });

  CatalogSearchBloc buildBloc() => CatalogSearchBloc(
        buscarCatalogoProductos: mockBuscarProductos,
        getPropietariosCatalogo: mockGetPropietarios,
        getCatalogoUbicaciones: mockGetCatalogoUbicaciones,
      );

  group('CatalogSearchBloc', () {
    test('estado inicial correcto', () {
      final bloc = buildBloc();
      expect(bloc.state.statusProductos, equals(CatalogStatus.initial));
      expect(bloc.state.statusUbicaciones, equals(CatalogStatus.initial));
      expect(bloc.state.hayMasProductos, isFalse);
      expect(bloc.state.propietarioProducto, isNull);
      expect(bloc.state.productosFiltrados, isEmpty);
      expect(bloc.state.ubicaciones, isEmpty);
      expect(bloc.state.ubicacionesFiltradas, isEmpty);
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
        'ubicaciones: emite loading si la carga supera el umbral',
        build: () {
          when(() => mockGetCatalogoUbicaciones(any())).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            return Right([tUbicacion1]);
          });
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CargarCatalogoUbicacionesEvent()),
        wait: const Duration(milliseconds: 400),
        expect: () => [
          const CatalogSearchState(statusUbicaciones: CatalogStatus.loading),
          isA<CatalogSearchState>()
              .having((s) => s.statusUbicaciones, 'status', CatalogStatus.success)
              .having((s) => s.ubicaciones, 'ubicaciones', [tUbicacion1]),
        ],
      );
    });

    group('CargarCatalogoUbicacionesEvent', () {
      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'carga ubicaciones, extrae y ordena almacenes disponibles',
        build: () {
          when(() => mockGetCatalogoUbicaciones(any())).thenAnswer(
            (_) async => Right([tUbicacion3, tUbicacion1, tUbicacion2]),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CargarCatalogoUbicacionesEvent()),
        expect: () => [
          CatalogSearchState(
            statusUbicaciones: CatalogStatus.success,
            ubicaciones: [tUbicacion3, tUbicacion1, tUbicacion2],
            ubicacionesFiltradas: [tUbicacion3, tUbicacion1, tUbicacion2],
            almacenesDisponibles: const ['Almacén Central', 'Almacén Repuestos'],
          ),
        ],
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'emite fallo cuando getCatalogoUbicaciones falla',
        build: () {
          when(() => mockGetCatalogoUbicaciones(any())).thenAnswer(
            (_) async => const Left(SinConexionFailure('Fallo de red')),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CargarCatalogoUbicacionesEvent()),
        expect: () => [
          const CatalogSearchState(
            statusUbicaciones: CatalogStatus.failure,
            mensajeErrorUbicaciones: 'Fallo de red',
            failureUbicaciones: SinConexionFailure('Fallo de red'),
          ),
        ],
      );
    });

    group('BuscarUbicacionesCatalogoEvent y FiltrarUbicacionesPorAlmacenEvent', () {
      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'filtra ubicaciones por código de barras',
        build: buildBloc,
        seed: () => CatalogSearchState(
          statusUbicaciones: CatalogStatus.success,
          ubicaciones: [tUbicacion1, tUbicacion2, tUbicacion3],
          ubicacionesFiltradas: [tUbicacion1, tUbicacion2, tUbicacion3],
          almacenesDisponibles: const ['Almacén Central', 'Almacén Repuestos'],
        ),
        act: (bloc) => bloc.add(const BuscarUbicacionesCatalogoEvent('LOC-B1')),
        expect: () => [
          CatalogSearchState(
            statusUbicaciones: CatalogStatus.success,
            ubicaciones: [tUbicacion1, tUbicacion2, tUbicacion3],
            ubicacionesFiltradas: [tUbicacion2],
            queryUbicacion: 'LOC-B1',
            almacenesDisponibles: const ['Almacén Central', 'Almacén Repuestos'],
          ),
        ],
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'filtra ubicaciones por almacén y permite limpiar el filtro con null',
        build: buildBloc,
        seed: () => CatalogSearchState(
          statusUbicaciones: CatalogStatus.success,
          ubicaciones: [tUbicacion1, tUbicacion2, tUbicacion3],
          ubicacionesFiltradas: [tUbicacion1, tUbicacion2, tUbicacion3],
          almacenesDisponibles: const ['Almacén Central', 'Almacén Repuestos'],
        ),
        act: (bloc) {
          bloc.add(const FiltrarUbicacionesPorAlmacenEvent('Almacén Repuestos'));
          bloc.add(const FiltrarUbicacionesPorAlmacenEvent(null));
        },
        expect: () => [
          CatalogSearchState(
            statusUbicaciones: CatalogStatus.success,
            ubicaciones: [tUbicacion1, tUbicacion2, tUbicacion3],
            ubicacionesFiltradas: [tUbicacion3],
            almacenUbicacionesFiltro: 'Almacén Repuestos',
            almacenesDisponibles: const ['Almacén Central', 'Almacén Repuestos'],
          ),
          CatalogSearchState(
            statusUbicaciones: CatalogStatus.success,
            ubicaciones: [tUbicacion1, tUbicacion2, tUbicacion3],
            ubicacionesFiltradas: [tUbicacion1, tUbicacion2, tUbicacion3],
            almacenUbicacionesFiltro: null,
            almacenesDisponibles: const ['Almacén Central', 'Almacén Repuestos'],
          ),
        ],
      );
    });
  });
}
