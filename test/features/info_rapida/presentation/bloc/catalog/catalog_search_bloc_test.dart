import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_productos_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_ubicaciones_usecase.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/catalog/catalog_search_bloc.dart';

class MockGetCatalogoProductosUseCase extends Mock
    implements GetCatalogoProductosUseCase {}

class MockGetCatalogoUbicacionesUseCase extends Mock
    implements GetCatalogoUbicacionesUseCase {}

void main() {
  late MockGetCatalogoProductosUseCase mockGetCatalogoProductos;
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
    registerFallbackValue(
      const GetCatalogoProductosParams(),
    );
    registerFallbackValue(
      const GetCatalogoUbicacionesParams(),
    );
  });

  setUp(() {
    mockGetCatalogoProductos = MockGetCatalogoProductosUseCase();
    mockGetCatalogoUbicaciones = MockGetCatalogoUbicacionesUseCase();
  });

  CatalogSearchBloc buildBloc() => CatalogSearchBloc(
        getCatalogoProductos: mockGetCatalogoProductos,
        getCatalogoUbicaciones: mockGetCatalogoUbicaciones,
      );

  group('CatalogSearchBloc', () {
    test('estado inicial correcto', () {
      final bloc = buildBloc();
      expect(bloc.state.statusProductos, equals(CatalogStatus.initial));
      expect(bloc.state.statusUbicaciones, equals(CatalogStatus.initial));
      expect(bloc.state.productos, isEmpty);
      expect(bloc.state.productosFiltrados, isEmpty);
      expect(bloc.state.ubicaciones, isEmpty);
      expect(bloc.state.ubicacionesFiltradas, isEmpty);
      expect(bloc.state.queryProducto, isEmpty);
      expect(bloc.state.queryUbicacion, isEmpty);
      expect(bloc.state.almacenUbicacionesFiltro, isNull);
      expect(bloc.state.almacenesDisponibles, isEmpty);
    });

    group('CargarCatalogoProductosEvent', () {
      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'carga productos exitosamente y aplica filtro actual si existe',
        build: () {
          when(() => mockGetCatalogoProductos(any())).thenAnswer(
            (_) async => Right([tProducto1, tProducto2, tProducto3]),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CargarCatalogoProductosEvent()),
        expect: () => [
          const CatalogSearchState(statusProductos: CatalogStatus.loading),
          CatalogSearchState(
            statusProductos: CatalogStatus.success,
            productos: [tProducto1, tProducto2, tProducto3],
            productosFiltrados: [tProducto1, tProducto2, tProducto3],
          ),
        ],
        verify: (_) {
          verify(
            () => mockGetCatalogoProductos(
              const GetCatalogoProductosParams(forceRefresh: false),
            ),
          ).called(1);
        },
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'con forceRefresh delega parámetro al caso de uso',
        build: () {
          when(() => mockGetCatalogoProductos(any())).thenAnswer(
            (_) async => Right([tProducto1]),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CargarCatalogoProductosEvent(forceRefresh: true)),
        expect: () => [
          const CatalogSearchState(statusProductos: CatalogStatus.loading),
          CatalogSearchState(
            statusProductos: CatalogStatus.success,
            productos: [tProducto1],
            productosFiltrados: [tProducto1],
          ),
        ],
        verify: (_) {
          verify(
            () => mockGetCatalogoProductos(
              const GetCatalogoProductosParams(forceRefresh: true),
            ),
          ).called(1);
        },
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'emite fallo cuando getCatalogoProductos retorna Failure',
        build: () {
          when(() => mockGetCatalogoProductos(any())).thenAnswer(
            (_) async => const Left(SinConexionFailure('Sin conexión')),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const CargarCatalogoProductosEvent()),
        expect: () => [
          const CatalogSearchState(statusProductos: CatalogStatus.loading),
          const CatalogSearchState(
            statusProductos: CatalogStatus.failure,
            mensajeErrorProductos: 'Sin conexión',
            failureProductos: SinConexionFailure('Sin conexión'),
          ),
        ],
      );
    });

    group('BuscarProductosCatalogoEvent', () {
      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'filtra productos por nombre',
        build: buildBloc,
        seed: () => CatalogSearchState(
          statusProductos: CatalogStatus.success,
          productos: [tProducto1, tProducto2, tProducto3],
          productosFiltrados: [tProducto1, tProducto2, tProducto3],
        ),
        act: (bloc) => bloc.add(const BuscarProductosCatalogoEvent('tornillo')),
        expect: () => [
          CatalogSearchState(
            statusProductos: CatalogStatus.success,
            productos: [tProducto1, tProducto2, tProducto3],
            productosFiltrados: [tProducto1],
            queryProducto: 'tornillo',
          ),
        ],
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'filtra productos por código interno',
        build: buildBloc,
        seed: () => CatalogSearchState(
          statusProductos: CatalogStatus.success,
          productos: [tProducto1, tProducto2, tProducto3],
          productosFiltrados: [tProducto1, tProducto2, tProducto3],
        ),
        act: (bloc) => bloc.add(const BuscarProductosCatalogoEvent('TUE-002')),
        expect: () => [
          CatalogSearchState(
            statusProductos: CatalogStatus.success,
            productos: [tProducto1, tProducto2, tProducto3],
            productosFiltrados: [tProducto2],
            queryProducto: 'TUE-002',
          ),
        ],
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'filtra productos por código de barras alternativo (otherBarcodes)',
        build: buildBloc,
        seed: () => CatalogSearchState(
          statusProductos: CatalogStatus.success,
          productos: [tProducto1, tProducto2, tProducto3],
          productosFiltrados: [tProducto1, tProducto2, tProducto3],
        ),
        act: (bloc) => bloc.add(const BuscarProductosCatalogoEvent('EXTRA-999')),
        expect: () => [
          CatalogSearchState(
            statusProductos: CatalogStatus.success,
            productos: [tProducto1, tProducto2, tProducto3],
            productosFiltrados: [tProducto3],
            queryProducto: 'EXTRA-999',
          ),
        ],
      );

      blocTest<CatalogSearchBloc, CatalogSearchState>(
        'query vacío restaura todos los productos',
        build: buildBloc,
        seed: () => CatalogSearchState(
          statusProductos: CatalogStatus.success,
          productos: [tProducto1, tProducto2, tProducto3],
          productosFiltrados: [tProducto1],
          queryProducto: 'tornillo',
        ),
        act: (bloc) => bloc.add(const BuscarProductosCatalogoEvent('')),
        expect: () => [
          CatalogSearchState(
            statusProductos: CatalogStatus.success,
            productos: [tProducto1, tProducto2, tProducto3],
            productosFiltrados: [tProducto1, tProducto2, tProducto3],
            queryProducto: '',
          ),
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
          const CatalogSearchState(statusUbicaciones: CatalogStatus.loading),
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
          const CatalogSearchState(statusUbicaciones: CatalogStatus.loading),
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
