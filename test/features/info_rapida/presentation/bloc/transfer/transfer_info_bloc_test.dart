import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/crear_transferencia_individual_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_ubicaciones_usecase.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/transfer/transfer_info_bloc.dart';

class MockCrearTransferenciaIndividualUseCase extends Mock
    implements CrearTransferenciaIndividualUseCase {}

class MockGetCatalogoUbicacionesUseCase extends Mock
    implements GetCatalogoUbicacionesUseCase {}

void main() {
  late MockCrearTransferenciaIndividualUseCase mockCrearTransferencia;
  late MockGetCatalogoUbicacionesUseCase mockGetCatalogoUbicaciones;

  const tUbicacionOrigen = UbicacionCatalogo(
    id: 10,
    name: 'WH/Stock/A1',
    barcode: 'LOC-A1',
    warehouseName: 'Almacén Central',
  );

  const tUbicacionDestino = UbicacionCatalogo(
    id: 20,
    name: 'WH/Stock/B1',
    barcode: 'LOC-B1',
    warehouseName: 'Almacén Central',
  );

  const tUbicacionDestino2 = UbicacionCatalogo(
    id: 30,
    name: 'REP/Stock/R1',
    barcode: 'LOC-R1',
    warehouseName: 'Almacén Repuestos',
  );

  const tTransferResult = TransferenciaIndividualResult(
    transferenciaId: 501,
    nombreTransferencia: 'WH/INT/00501',
    cantidadEnviada: 5.0,
  );

  setUpAll(() {
    registerFallbackValue(
      const GetCatalogoUbicacionesParams(),
    );
    registerFallbackValue(
      const CrearTransferenciaIndividualParams(
        idAlmacen: 1,
        idMove: 100,
        idProducto: 1,
        idLote: 1,
        idUbicacionOrigen: 10,
        idUbicacionDestino: 20,
        cantidadEnviada: 5.0,
        idOperario: 42,
        fechaTransaccion: '2026-10-08 10:00:00',
        observacion: '',
        idPropietario: 0,
        dateStart: '2026-10-08 09:00:00',
        dateEnd: '2026-10-08 10:00:00',
      ),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'userId': 42});
    mockCrearTransferencia = MockCrearTransferenciaIndividualUseCase();
    mockGetCatalogoUbicaciones = MockGetCatalogoUbicacionesUseCase();
  });

  TransferInfoBloc buildBloc() => TransferInfoBloc(
        crearTransferencia: mockCrearTransferencia,
        getCatalogoUbicaciones: mockGetCatalogoUbicaciones,
      );

  group('TransferInfoBloc', () {
    test('estado inicial correcto', () {
      final bloc = buildBloc();
      expect(bloc.state.status, equals(TransferInfoStatus.initial));
      expect(bloc.state.puedeTransferir, isFalse);
      expect(bloc.state.ubicacionDestino, isNull);
      expect(bloc.state.ubicacionesDestino, isEmpty);
    });

    group('TransferInfoInicializado', () {
      blocTest<TransferInfoBloc, TransferInfoState>(
        'inicializa datos y carga ubicaciones excluyendo origen',
        build: () {
          when(() => mockGetCatalogoUbicaciones(any())).thenAnswer(
            (_) async => const Right([
              tUbicacionOrigen,
              tUbicacionDestino,
              tUbicacionDestino2,
            ]),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const TransferInfoInicializado(
          idAlmacen: 1,
          idMove: 101,
          idProducto: 15,
          nombreProducto: 'Tornillo M6',
          idLote: 3,
          nombreLote: 'LOT-99',
          idUbicacionOrigen: 10,
          nombreUbicacionOrigen: 'WH/Stock/A1',
          cantidadDisponible: 20.0,
          idPropietario: 2,
          propietario: 'Proveedor X',
          manejoPropietario: true,
        )),
        expect: () => [
          isA<TransferInfoState>()
              .having((s) => s.status, 'status', TransferInfoStatus.ready)
              .having((s) => s.idProducto, 'idProducto', 15)
              .having((s) => s.nombreProducto, 'nombreProducto', 'Tornillo M6')
              .having((s) => s.cantidadDisponible, 'cantidadDisponible', 20.0)
              .having((s) => s.idUbicacionOrigen, 'idUbicacionOrigen', 10),
          isA<TransferInfoState>()
              .having((s) => s.ubicacionesDestino, 'ubicacionesDestino',
                  [tUbicacionDestino, tUbicacionDestino2])
              .having((s) => s.almacenesDisponibles, 'almacenesDisponibles',
                  ['Almacén Central', 'Almacén Repuestos']),
        ],
      );

      blocTest<TransferInfoBloc, TransferInfoState>(
        'cuando getCatalogoUbicaciones falla, emite mensajeError y failure',
        build: () {
          when(() => mockGetCatalogoUbicaciones(any())).thenAnswer(
            (_) async => const Left(SinConexionFailure('Fallo de conexión')),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const TransferInfoInicializado(
          idAlmacen: 1,
          idMove: 101,
          idProducto: 15,
          nombreProducto: 'Tornillo M6',
          idLote: 3,
          nombreLote: 'LOT-99',
          idUbicacionOrigen: 10,
          nombreUbicacionOrigen: 'WH/Stock/A1',
          cantidadDisponible: 20.0,
        )),
        expect: () => [
          isA<TransferInfoState>()
              .having((s) => s.status, 'status', TransferInfoStatus.ready),
          isA<TransferInfoState>()
              .having((s) => s.mensajeError, 'mensajeError', 'Fallo de conexión')
              .having((s) => s.failure, 'failure',
                  const SinConexionFailure('Fallo de conexión')),
        ],
      );
    });

    group('Selección y escaneo de ubicación destino', () {
      blocTest<TransferInfoBloc, TransferInfoState>(
        'SeleccionarUbicacionDestinoEvent exitoso asigna destino válido',
        build: buildBloc,
        seed: () => const TransferInfoState(
          status: TransferInfoStatus.ready,
          idUbicacionOrigen: 10,
        ),
        act: (bloc) => bloc.add(
          const SeleccionarUbicacionDestinoEvent(tUbicacionDestino),
        ),
        expect: () => [
          const TransferInfoState(
            status: TransferInfoStatus.ready,
            idUbicacionOrigen: 10,
            ubicacionDestino: tUbicacionDestino,
            ubicacionDestinoValida: true,
          ),
        ],
      );

      blocTest<TransferInfoBloc, TransferInfoState>(
        'SeleccionarUbicacionDestinoEvent con misma ubicación de origen rechaza selección',
        build: buildBloc,
        seed: () => const TransferInfoState(
          status: TransferInfoStatus.ready,
          idUbicacionOrigen: 10,
        ),
        act: (bloc) => bloc.add(
          const SeleccionarUbicacionDestinoEvent(tUbicacionOrigen),
        ),
        expect: () => [
          const TransferInfoState(
            status: TransferInfoStatus.ready,
            idUbicacionOrigen: 10,
            ubicacionDestinoValida: false,
            mensajeError: 'La ubicación destino no puede ser la misma de origen',
            failure: InfoRapidaValidationFailure(
              'La ubicación destino no puede ser la misma de origen',
            ),
          ),
        ],
      );

      blocTest<TransferInfoBloc, TransferInfoState>(
        'EscanearUbicacionDestinoEvent encuentra ubicación por código de barras',
        build: buildBloc,
        seed: () => const TransferInfoState(
          status: TransferInfoStatus.ready,
          idUbicacionOrigen: 10,
          ubicacionesDestino: [tUbicacionDestino, tUbicacionDestino2],
        ),
        act: (bloc) =>
            bloc.add(const EscanearUbicacionDestinoEvent('LOC-B1')),
        expect: () => [
          const TransferInfoState(
            status: TransferInfoStatus.ready,
            idUbicacionOrigen: 10,
            ubicacionesDestino: [tUbicacionDestino, tUbicacionDestino2],
            ubicacionDestino: tUbicacionDestino,
            ubicacionDestinoValida: true,
          ),
        ],
      );

      blocTest<TransferInfoBloc, TransferInfoState>(
        'EscanearUbicacionDestinoEvent con código inexistente emite error',
        build: buildBloc,
        seed: () => const TransferInfoState(
          status: TransferInfoStatus.ready,
          idUbicacionOrigen: 10,
          ubicacionesDestino: [tUbicacionDestino],
        ),
        act: (bloc) =>
            bloc.add(const EscanearUbicacionDestinoEvent('LOC-INEXISTENTE')),
        expect: () => [
          const TransferInfoState(
            status: TransferInfoStatus.ready,
            idUbicacionOrigen: 10,
            ubicacionesDestino: [tUbicacionDestino],
            mensajeError:
                'Ubicación con código "loc-inexistente" no encontrada',
            failure: InfoRapidaValidationFailure(
              'Ubicación con código "loc-inexistente" no encontrada',
            ),
          ),
        ],
      );
    });

    group('Cambio de cantidad y observación', () {
      blocTest<TransferInfoBloc, TransferInfoState>(
        'CambiarCantidadTransferEvent con valor positivo válido actualiza cantidadValida a true',
        build: buildBloc,
        seed: () => const TransferInfoState(
          status: TransferInfoStatus.ready,
          cantidadDisponible: 10.0,
        ),
        act: (bloc) => bloc.add(const CambiarCantidadTransferEvent(7.5)),
        expect: () => [
          const TransferInfoState(
            status: TransferInfoStatus.ready,
            cantidadDisponible: 10.0,
            cantidadATransferir: 7.5,
            cantidadValida: true,
          ),
        ],
      );

      blocTest<TransferInfoBloc, TransferInfoState>(
        'CambiarCantidadTransferEvent con 0 emite error',
        build: buildBloc,
        seed: () => const TransferInfoState(
          status: TransferInfoStatus.ready,
          cantidadDisponible: 10.0,
        ),
        act: (bloc) => bloc.add(const CambiarCantidadTransferEvent(0.0)),
        expect: () => [
          const TransferInfoState(
            status: TransferInfoStatus.ready,
            cantidadDisponible: 10.0,
            cantidadATransferir: 0.0,
            cantidadValida: false,
            mensajeError: 'La cantidad a transferir debe ser mayor a 0',
            failure: InfoRapidaValidationFailure(
              'La cantidad a transferir debe ser mayor a 0',
            ),
          ),
        ],
      );

      blocTest<TransferInfoBloc, TransferInfoState>(
        'CambiarCantidadTransferEvent superior a la disponible emite error',
        build: buildBloc,
        seed: () => const TransferInfoState(
          status: TransferInfoStatus.ready,
          cantidadDisponible: 10.0,
        ),
        act: (bloc) => bloc.add(const CambiarCantidadTransferEvent(15.0)),
        expect: () => [
          const TransferInfoState(
            status: TransferInfoStatus.ready,
            cantidadDisponible: 10.0,
            cantidadATransferir: 15.0,
            cantidadValida: false,
            mensajeError: 'La cantidad no puede superar la disponible (10.0)',
            failure: InfoRapidaValidationFailure(
              'La cantidad no puede superar la disponible (10.0)',
            ),
          ),
        ],
      );

      blocTest<TransferInfoBloc, TransferInfoState>(
        'CambiarObservacionTransferEvent actualiza campo observacion',
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const CambiarObservacionTransferEvent('Reubicación urgente')),
        expect: () => [
          const TransferInfoState(observacion: 'Reubicación urgente'),
        ],
      );
    });

    group('ConfirmarTransferenciaIndividualEvent', () {
      blocTest<TransferInfoBloc, TransferInfoState>(
        'si puedeTransferir es false emite error de validación sin llamar usecase',
        build: buildBloc,
        seed: () => const TransferInfoState(
          status: TransferInfoStatus.ready,
          cantidadValida: false,
        ),
        act: (bloc) =>
            bloc.add(const ConfirmarTransferenciaIndividualEvent()),
        expect: () => [
          const TransferInfoState(
            status: TransferInfoStatus.ready,
            cantidadValida: false,
            mensajeError:
                'Verifica la ubicación destino y la cantidad antes de transferir',
            failure: InfoRapidaValidationFailure(
              'Verifica la ubicación destino y la cantidad antes de transferir',
            ),
          ),
        ],
        verify: (_) {
          verifyNever(() => mockCrearTransferencia(any()));
        },
      );

      blocTest<TransferInfoBloc, TransferInfoState>(
        'confirmación exitosa emite loading y luego success con resultado',
        build: () {
          when(() => mockCrearTransferencia(any())).thenAnswer(
            (_) async => const Right(tTransferResult),
          );
          return buildBloc();
        },
        seed: () => const TransferInfoState(
          status: TransferInfoStatus.ready,
          idAlmacen: 1,
          idMove: 101,
          idProducto: 15,
          idLote: 3,
          idUbicacionOrigen: 10,
          ubicacionDestino: tUbicacionDestino,
          ubicacionDestinoValida: true,
          cantidadDisponible: 20.0,
          cantidadATransferir: 5.0,
          cantidadValida: true,
          dateStart: '2026-10-08 09:00:00',
        ),
        act: (bloc) =>
            bloc.add(const ConfirmarTransferenciaIndividualEvent()),
        expect: () => [
          isA<TransferInfoState>()
              .having((s) => s.status, 'status', TransferInfoStatus.loading),
          isA<TransferInfoState>()
              .having((s) => s.status, 'status', TransferInfoStatus.success)
              .having((s) => s.resultadoTransferencia, 'resultado',
                  tTransferResult),
        ],
        verify: (_) {
          verify(() => mockCrearTransferencia(any())).called(1);
        },
      );

      blocTest<TransferInfoBloc, TransferInfoState>(
        'confirmación fallida emite loading y luego failure con mensaje de error',
        build: () {
          when(() => mockCrearTransferencia(any())).thenAnswer(
            (_) async => const Left(SinConexionFailure('Sin conexión al servidor')),
          );
          return buildBloc();
        },
        seed: () => const TransferInfoState(
          status: TransferInfoStatus.ready,
          idAlmacen: 1,
          idMove: 101,
          idProducto: 15,
          idLote: 3,
          idUbicacionOrigen: 10,
          ubicacionDestino: tUbicacionDestino,
          ubicacionDestinoValida: true,
          cantidadDisponible: 20.0,
          cantidadATransferir: 5.0,
          cantidadValida: true,
        ),
        act: (bloc) =>
            bloc.add(const ConfirmarTransferenciaIndividualEvent()),
        expect: () => [
          isA<TransferInfoState>()
              .having((s) => s.status, 'status', TransferInfoStatus.loading),
          isA<TransferInfoState>()
              .having((s) => s.status, 'status', TransferInfoStatus.failure)
              .having((s) => s.mensajeError, 'mensajeError',
                  'Sin conexión al servidor')
              .having((s) => s.failure, 'failure',
                  const SinConexionFailure('Sin conexión al servidor')),
        ],
      );
    });

    group('LimpiarMensajeTransferEvent', () {
      blocTest<TransferInfoBloc, TransferInfoState>(
        'limpia mensajeError y failure del estado',
        build: buildBloc,
        seed: () => const TransferInfoState(
          mensajeError: 'Error previo',
          failure: InfoRapidaValidationFailure('Error previo'),
        ),
        act: (bloc) => bloc.add(const LimpiarMensajeTransferEvent()),
        expect: () => [
          const TransferInfoState(
            mensajeError: null,
            failure: null,
          ),
        ],
      );
    });
  });
}
