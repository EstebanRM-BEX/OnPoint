import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/actualizar_ubicacion_usecase.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/location/location_info_bloc.dart';

class MockActualizarUbicacionUseCase extends Mock
    implements ActualizarUbicacionUseCase {}

void main() {
  late MockActualizarUbicacionUseCase mockActualizarUbicacion;

  final tProducto1 = const ProductoUbicacion(
    id: 1,
    producto: 'Arandela 1/2',
    codigoBarras: '770001',
    cantidad: 10.0,
    lote: 'LOTE-1',
    manejoPropietario: true,
    propietario: 'Empresa A',
  );

  final tProducto2 = const ProductoUbicacion(
    id: 2,
    producto: 'Tornillo 3/8',
    codigoBarras: '770002',
    cantidad: 5.0,
    lote: 'LOTE-2',
    manejoPropietario: true,
    propietario: 'Empresa A',
  );

  final tProductoDistintoPropietario = const ProductoUbicacion(
    id: 3,
    producto: 'Clavo Acero',
    codigoBarras: '770003',
    cantidad: 20.0,
    lote: 'LOTE-3',
    manejoPropietario: true,
    propietario: 'Empresa B',
  );

  final tUbicacion = UbicacionInfo(
    id: 10,
    nombre: 'A-01',
    codigoBarras: 'LOC-A01',
    nombreAlmacen: 'Central',
    ubicacionPadre: 'Stock',
    numeroProductos: 3,
    productos: [tProducto2, tProducto1, tProductoDistintoPropietario],
  );

  setUpAll(() {
    registerFallbackValue(
      const ActualizarUbicacionParams(
        locationId: 10,
        name: 'A-01',
        barcode: 'LOC-A01',
      ),
    );
  });

  setUp(() {
    mockActualizarUbicacion = MockActualizarUbicacionUseCase();
  });

  LocationInfoBloc buildBloc() {
    return LocationInfoBloc(
      actualizarUbicacion: mockActualizarUbicacion,
    );
  }

  group('LocationInfoBloc', () {
    test('estado inicial correcto', () {
      final bloc = buildBloc();
      expect(bloc.state, const LocationInfoState());
      bloc.close();
    });

    blocTest<LocationInfoBloc, LocationInfoState>(
      'LocationInfoInicializado ordena productos por default (name asc)',
      build: buildBloc,
      act: (bloc) => bloc.add(LocationInfoInicializado(tUbicacion)),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          productosFiltrados: [tProducto1, tProductoDistintoPropietario, tProducto2],
          queryFiltro: '',
          criterioOrden: 'name',
          ordenAscendente: true,
        ),
      ],
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'BuscarProductosUbicacionEvent filtra productos por nombre',
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
        productosFiltrados: [tProducto1, tProductoDistintoPropietario, tProducto2],
      ),
      act: (bloc) => bloc.add(const BuscarProductosUbicacionEvent('Arandela')),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          productosFiltrados: [tProducto1],
          queryFiltro: 'Arandela',
        ),
      ],
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'OrdenarProductosUbicacionEvent ordena por cantidad descendente',
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
        productosFiltrados: [tProducto1, tProductoDistintoPropietario, tProducto2],
      ),
      act: (bloc) => bloc.add(const OrdenarProductosUbicacionEvent(
        criterio: 'cantidad',
        ascendente: false,
      )),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          productosFiltrados: [tProductoDistintoPropietario, tProducto1, tProducto2], // 20, 10, 5
          criterioOrden: 'cantidad',
          ordenAscendente: false,
        ),
      ],
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'ToggleModoEdicionUbicacionEvent activa y desactiva modo edición',
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
      ),
      act: (bloc) => bloc.add(const ToggleModoEdicionUbicacionEvent(true)),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          isEditing: true,
        ),
      ],
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'GuardarEdicionUbicacionEvent exitoso actualiza ubicación',
      setUp: () {
        when(() => mockActualizarUbicacion(any())).thenAnswer(
          (_) async => Right(tUbicacion.copyWith(nombre: 'A-01-MOD')),
        );
      },
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
        productosFiltrados: [tProducto1],
        isEditing: true,
      ),
      act: (bloc) => bloc.add(const GuardarEdicionUbicacionEvent(
        nombre: 'A-01-MOD',
        barcode: 'LOC-A01',
      )),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          productosFiltrados: [tProducto1],
          isEditing: true,
          isSaving: true,
        ),
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion.copyWith(nombre: 'A-01-MOD'),
          productosFiltrados: [tProducto1, tProductoDistintoPropietario, tProducto2],
          isEditing: false,
          isSaving: false,
          mensajeExito: 'Ubicación actualizada exitosamente',
        ),
      ],
      verify: (_) {
        verify(() => mockActualizarUbicacion(any())).called(1);
      },
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'GuardarEdicionUbicacionEvent con fallo emite mensajeError y failure',
      setUp: () {
        when(() => mockActualizarUbicacion(any())).thenAnswer(
          (_) async => const Left(SinConexionFailure('Sin conexión')),
        );
      },
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
        isEditing: true,
      ),
      act: (bloc) => bloc.add(const GuardarEdicionUbicacionEvent(
        nombre: 'A-01-MOD',
        barcode: 'LOC-A01',
      )),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          isEditing: true,
          isSaving: true,
        ),
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          isEditing: true,
          isSaving: false,
          mensajeError: 'Sin conexión',
          failure: const SinConexionFailure('Sin conexión'),
        ),
      ],
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'ToggleModoSeleccionMasivaEvent activa modo y al desactivar vacía selección',
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
        modoSeleccionMasiva: true,
        productosSeleccionados: [tProducto1],
      ),
      act: (bloc) => bloc.add(const ToggleModoSeleccionMasivaEvent(false)),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          modoSeleccionMasiva: false,
          productosSeleccionados: const [],
        ),
      ],
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'ToggleProductoSeleccionadoEvent agrega producto compatible a la selección',
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
        modoSeleccionMasiva: true,
        productosSeleccionados: [tProducto1],
      ),
      act: (bloc) => bloc.add(ToggleProductoSeleccionadoEvent(tProducto2, true)),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          modoSeleccionMasiva: true,
          productosSeleccionados: [tProducto1, tProducto2],
        ),
      ],
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'ToggleProductoSeleccionadoEvent con producto de distinto propietario rechaza selección',
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
        modoSeleccionMasiva: true,
        productosSeleccionados: [tProducto1],
      ),
      act: (bloc) => bloc.add(ToggleProductoSeleccionadoEvent(
        tProductoDistintoPropietario,
        true,
      )),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          modoSeleccionMasiva: true,
          productosSeleccionados: [tProducto1],
          mensajeError:
              'No puedes mezclar productos de "Empresa A" con productos de "Empresa B"',
          failure: const PropietarioMismatchFailure(
            'No puedes mezclar productos de "Empresa A" con productos de "Empresa B"',
          ),
        ),
      ],
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'ToggleProductoSeleccionadoEvent deselecciona producto correctamente',
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
        modoSeleccionMasiva: true,
        productosSeleccionados: [tProducto1, tProducto2],
      ),
      act: (bloc) => bloc.add(ToggleProductoSeleccionadoEvent(tProducto1, false)),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          modoSeleccionMasiva: true,
          productosSeleccionados: [tProducto2],
        ),
      ],
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'DeseleccionarTodosProductosEvent vacía selección',
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
        modoSeleccionMasiva: true,
        productosSeleccionados: [tProducto1, tProducto2],
      ),
      act: (bloc) => bloc.add(const DeseleccionarTodosProductosEvent()),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          modoSeleccionMasiva: true,
          productosSeleccionados: const [],
        ),
      ],
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'LimpiarMensajeUbicacionEvent limpia mensajes',
      build: buildBloc,
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: tUbicacion,
        mensajeExito: 'Éxito',
        mensajeError: 'Error',
      ),
      act: (bloc) => bloc.add(const LimpiarMensajeUbicacionEvent()),
      expect: () => [
        LocationInfoState(
          status: LocationInfoStatus.ready,
          ubicacion: tUbicacion,
          mensajeExito: null,
          mensajeError: null,
          failure: null,
        ),
      ],
    );
  });
}
