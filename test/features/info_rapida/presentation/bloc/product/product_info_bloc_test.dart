import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/actualizar_producto_usecase.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/product/product_info_bloc.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_url_imagen_producto.dart';

class MockActualizarProductoUseCase extends Mock
    implements ActualizarProductoUseCase {}

class MockGetUrlImagenProducto extends Mock implements GetUrlImagenProducto {}

void main() {
  late MockActualizarProductoUseCase mockActualizarProducto;
  late MockGetUrlImagenProducto mockGetUrlImagenProducto;

  final tUbicacion1 = const UbicacionProducto(
    idUbicacion: 10,
    ubicacion: 'B-01',
    codigoBarras: 'LOC-B01',
    cantidad: 20.0,
    lote: 'LOTE-B',
    fechaEntrada: '2026-01-02',
  );

  final tUbicacion2 = const UbicacionProducto(
    idUbicacion: 11,
    ubicacion: 'A-01',
    codigoBarras: 'LOC-A01',
    cantidad: 50.0,
    lote: 'LOTE-A',
    fechaEntrada: '2026-01-01',
  );

  final tProducto = ProductoInfo(
    id: 1,
    nombre: 'Tuerca 1/4',
    referencia: 'TU-14',
    codigoBarras: '770001',
    cantidadDisponible: 70.0,
    unidadMedida: 'un.',
    ubicaciones: [tUbicacion1, tUbicacion2],
  );

  setUpAll(() {
    registerFallbackValue(
      const ActualizarProductoParams(
        productId: 1,
        name: 'test',
        barcode: 'test',
        defaultCode: 'test',
        listPrice: '10',
        weight: '1',
        volume: '1',
      ),
    );
    registerFallbackValue(
      const GetUrlImagenProductoParams(productId: 1),
    );
  });

  setUp(() {
    mockActualizarProducto = MockActualizarProductoUseCase();
    mockGetUrlImagenProducto = MockGetUrlImagenProducto();
  });

  ProductInfoBloc buildBloc() {
    return ProductInfoBloc(
      actualizarProducto: mockActualizarProducto,
      getUrlImagenProducto: mockGetUrlImagenProducto,
    );
  }

  group('ProductInfoBloc', () {
    test('estado inicial correcto', () {
      final bloc = buildBloc();
      expect(bloc.state, const ProductInfoState());
      bloc.close();
    });

    blocTest<ProductInfoBloc, ProductInfoState>(
      'ProductInfoInicializado ordena ubicaciones por default (location asc)',
      build: buildBloc,
      act: (bloc) => bloc.add(ProductInfoInicializado(tProducto)),
      expect: () => [
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          ubicacionesFiltradas: [tUbicacion2, tUbicacion1], // A-01 antes de B-01
          queryFiltro: '',
          criterioOrden: 'location',
          ordenAscendente: true,
          isEditing: false,
          isSaving: false,
        ),
      ],
    );

    blocTest<ProductInfoBloc, ProductInfoState>(
      'BuscarUbicacionesProductoEvent filtra por nombre de ubicación',
      build: buildBloc,
      seed: () => ProductInfoState(
        status: ProductInfoStatus.ready,
        producto: tProducto,
        ubicacionesFiltradas: [tUbicacion2, tUbicacion1],
      ),
      act: (bloc) => bloc.add(const BuscarUbicacionesProductoEvent('B-01')),
      expect: () => [
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          ubicacionesFiltradas: [tUbicacion1],
          queryFiltro: 'B-01',
        ),
      ],
    );

    blocTest<ProductInfoBloc, ProductInfoState>(
      'BuscarUbicacionesProductoEvent filtra por lote',
      build: buildBloc,
      seed: () => ProductInfoState(
        status: ProductInfoStatus.ready,
        producto: tProducto,
        ubicacionesFiltradas: [tUbicacion2, tUbicacion1],
      ),
      act: (bloc) => bloc.add(const BuscarUbicacionesProductoEvent('LOTE-A')),
      expect: () => [
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          ubicacionesFiltradas: [tUbicacion2],
          queryFiltro: 'LOTE-A',
        ),
      ],
    );

    blocTest<ProductInfoBloc, ProductInfoState>(
      'OrdenarUbicacionesProductoEvent ordena por cantidad descendente',
      build: buildBloc,
      seed: () => ProductInfoState(
        status: ProductInfoStatus.ready,
        producto: tProducto,
        ubicacionesFiltradas: [tUbicacion2, tUbicacion1],
      ),
      act: (bloc) => bloc.add(const OrdenarUbicacionesProductoEvent(
        criterio: 'cantidad',
        ascendente: false,
      )),
      expect: () => [
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          ubicacionesFiltradas: [tUbicacion2, tUbicacion1], // 50.0 luego 20.0
          criterioOrden: 'cantidad',
          ordenAscendente: false,
        ),
      ],
    );

    blocTest<ProductInfoBloc, ProductInfoState>(
      'ToggleModoEdicionProductoEvent alterna modo edición',
      build: buildBloc,
      seed: () => ProductInfoState(
        status: ProductInfoStatus.ready,
        producto: tProducto,
      ),
      act: (bloc) => bloc.add(const ToggleModoEdicionProductoEvent(true)),
      expect: () => [
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          isEditing: true,
        ),
      ],
    );

    blocTest<ProductInfoBloc, ProductInfoState>(
      'CargarImagenProductoEvent exitoso actualiza imageUrl',
      setUp: () {
        when(() => mockGetUrlImagenProducto(any())).thenAnswer(
          (_) async => const Right('https://example.com/image.png'),
        );
      },
      build: buildBloc,
      seed: () => ProductInfoState(
        status: ProductInfoStatus.ready,
        producto: tProducto,
      ),
      act: (bloc) => bloc.add(const CargarImagenProductoEvent()),
      expect: () => [
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          isLoadingImage: true,
        ),
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          isLoadingImage: false,
          imageUrl: 'https://example.com/image.png',
        ),
      ],
      verify: (_) {
        verify(
          () => mockGetUrlImagenProducto(
            any(
              that: isA<GetUrlImagenProductoParams>().having(
                (p) => p.productId,
                'productId',
                1,
              ),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<ProductInfoBloc, ProductInfoState>(
      'GuardarEdicionProductoEvent exitoso actualiza producto y emite mensajeExito',
      setUp: () {
        when(() => mockActualizarProducto(any())).thenAnswer(
          (_) async => Right(tProducto.copyWith(nombre: 'Tuerca 1/4 Modificada')),
        );
      },
      build: buildBloc,
      seed: () => ProductInfoState(
        status: ProductInfoStatus.ready,
        producto: tProducto,
        ubicacionesFiltradas: [tUbicacion2, tUbicacion1],
        isEditing: true,
      ),
      act: (bloc) => bloc.add(const GuardarEdicionProductoEvent(
        nombre: 'Tuerca 1/4 Modificada',
        barcode: '770001',
        defaultCode: 'TU-14',
        listPrice: '1500',
        weight: '0.05',
        volume: '0.001',
      )),
      expect: () => [
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          ubicacionesFiltradas: [tUbicacion2, tUbicacion1],
          isEditing: true,
          isSaving: true,
        ),
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto.copyWith(nombre: 'Tuerca 1/4 Modificada'),
          ubicacionesFiltradas: [tUbicacion2, tUbicacion1],
          isEditing: false,
          isSaving: false,
          mensajeExito: 'Producto actualizado exitosamente',
        ),
      ],
      verify: (_) {
        verify(() => mockActualizarProducto(any())).called(1);
      },
    );

    blocTest<ProductInfoBloc, ProductInfoState>(
      'GuardarEdicionProductoEvent fallido emite failure y mensajeError',
      setUp: () {
        when(() => mockActualizarProducto(any())).thenAnswer(
          (_) async => const Left(SinConexionFailure('Sin conexión')),
        );
      },
      build: buildBloc,
      seed: () => ProductInfoState(
        status: ProductInfoStatus.ready,
        producto: tProducto,
        isEditing: true,
      ),
      act: (bloc) => bloc.add(const GuardarEdicionProductoEvent(
        nombre: 'Tuerca',
        barcode: '770001',
        defaultCode: 'TU-14',
        listPrice: '10',
        weight: '1',
        volume: '1',
      )),
      expect: () => [
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          isEditing: true,
          isSaving: true,
        ),
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          isEditing: true,
          isSaving: false,
          mensajeError: 'Sin conexión',
          failure: const SinConexionFailure('Sin conexión'),
        ),
      ],
    );

    blocTest<ProductInfoBloc, ProductInfoState>(
      'LimpiarMensajeProductoEvent limpia mensajeExito y mensajeError',
      build: buildBloc,
      seed: () => ProductInfoState(
        status: ProductInfoStatus.ready,
        producto: tProducto,
        mensajeExito: 'Éxito',
        mensajeError: 'Error',
      ),
      act: (bloc) => bloc.add(const LimpiarMensajeProductoEvent()),
      expect: () => [
        ProductInfoState(
          status: ProductInfoStatus.ready,
          producto: tProducto,
          mensajeExito: null,
          mensajeError: null,
          failure: null,
        ),
      ],
    );
  });
}
