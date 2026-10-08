import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/crear_transferencia_masiva_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_ubicaciones_usecase.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/mass_transfer/mass_transfer_bloc.dart';

class MockCrearTransferenciaMasivaUseCase extends Mock
    implements CrearTransferenciaMasivaUseCase {}

class MockGetCatalogoUbicacionesUseCase extends Mock
    implements GetCatalogoUbicacionesUseCase {}

void main() {
  late MockCrearTransferenciaMasivaUseCase mockCrearTransferenciaMasiva;
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

  const tProducto1 = ProductoUbicacion(
    id: 101,
    producto: 'Tornillo M6',
    codigoBarras: '770001',
    cantidad: 15.0,
    cantidadMano: 15.0,
    loteId: 1,
    lote: 'L-1',
    manejoPropietario: true,
    propietario: 'Empresa A',
  );

  const tProducto2 = ProductoUbicacion(
    id: 102,
    producto: 'Tuerca M6',
    codigoBarras: '770002',
    cantidad: 25.0,
    cantidadMano: 25.0,
    loteId: 2,
    lote: 'L-2',
    manejoPropietario: true,
    propietario: 'Empresa A',
  );

  const tProductoDistintoPropietario = ProductoUbicacion(
    id: 103,
    producto: 'Arandela',
    codigoBarras: '770003',
    cantidad: 50.0,
    cantidadMano: 50.0,
    loteId: 3,
    lote: 'L-3',
    manejoPropietario: true,
    propietario: 'Empresa B',
  );

  const tTransferMasivaResult = TransferenciaMasivaResult(
    transferenciaId: 9001,
    nombreTransferencia: 'WH/MAS/09001',
    totalItems: 2,
  );

  setUpAll(() {
    registerFallbackValue(
      const GetCatalogoUbicacionesParams(),
    );
    registerFallbackValue(
      const CrearTransferenciaMasivaParams(
        dateStart: '2026-10-08 09:00:00',
        dateEnd: '2026-10-08 10:00:00',
        idAlmacen: 1,
        idUbicacionOrigen: 10,
        idUbicacionDestino: 20,
        idOperario: 42,
        fechaTransaccion: '2026-10-08 10:00:00',
        listItems: [],
      ),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'userId': 42});
    mockCrearTransferenciaMasiva = MockCrearTransferenciaMasivaUseCase();
    mockGetCatalogoUbicaciones = MockGetCatalogoUbicacionesUseCase();
  });

  MassTransferBloc buildBloc() => MassTransferBloc(
        crearTransferenciaMasiva: mockCrearTransferenciaMasiva,
        getCatalogoUbicaciones: mockGetCatalogoUbicaciones,
      );

  group('MassTransferBloc', () {
    test('estado inicial correcto', () {
      final bloc = buildBloc();
      expect(bloc.state.status, equals(MassTransferStatus.initial));
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.puedeTransferir, isFalse);
    });

    group('MassTransferInicializado', () {
      blocTest<MassTransferBloc, MassTransferState>(
        'inicializa items con cantidades disponibles y carga ubicaciones excluyendo origen',
        build: () {
          when(() => mockGetCatalogoUbicaciones(any())).thenAnswer(
            (_) async => const Right([tUbicacionOrigen, tUbicacionDestino]),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const MassTransferInicializado(
          idAlmacen: 1,
          idUbicacionOrigen: 10,
          nombreUbicacionOrigen: 'WH/Stock/A1',
          productosSeleccionados: [tProducto1, tProducto2],
        )),
        expect: () => [
          isA<MassTransferState>()
              .having((s) => s.status, 'status', MassTransferStatus.ready)
              .having((s) => s.idAlmacen, 'idAlmacen', 1)
              .having((s) => s.idUbicacionOrigen, 'idUbicacionOrigen', 10)
              .having((s) => s.items.length, 'total items', 2)
              .having((s) => s.items[0].cantidadATransferir, 'item1 qty', 15.0)
              .having((s) => s.items[1].cantidadATransferir, 'item2 qty', 25.0),
          isA<MassTransferState>()
              .having((s) => s.ubicacionesDestino, 'destinos', [tUbicacionDestino])
              .having((s) => s.almacenesDisponibles, 'almacenes', ['Almacén Central']),
        ],
      );

      blocTest<MassTransferBloc, MassTransferState>(
        'emite fallo cuando getCatalogoUbicaciones falla',
        build: () {
          when(() => mockGetCatalogoUbicaciones(any())).thenAnswer(
            (_) async => const Left(SinConexionFailure('Sin red')),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const MassTransferInicializado(
          idAlmacen: 1,
          idUbicacionOrigen: 10,
          nombreUbicacionOrigen: 'WH/Stock/A1',
          productosSeleccionados: [tProducto1],
        )),
        expect: () => [
          isA<MassTransferState>()
              .having((s) => s.status, 'status', MassTransferStatus.ready),
          isA<MassTransferState>()
              .having((s) => s.mensajeError, 'mensajeError', 'Sin red')
              .having((s) => s.failure, 'failure',
                  const SinConexionFailure('Sin red')),
        ],
      );
    });

    group('Selección y escaneo de ubicación destino', () {
      blocTest<MassTransferBloc, MassTransferState>(
        'SeleccionarUbicacionDestinoMassEvent asigna destino válido',
        build: buildBloc,
        seed: () => const MassTransferState(
          status: MassTransferStatus.ready,
          idUbicacionOrigen: 10,
        ),
        act: (bloc) => bloc.add(
          const SeleccionarUbicacionDestinoMassEvent(tUbicacionDestino),
        ),
        expect: () => [
          const MassTransferState(
            status: MassTransferStatus.ready,
            idUbicacionOrigen: 10,
            ubicacionDestino: tUbicacionDestino,
            ubicacionDestinoValida: true,
          ),
        ],
      );

      blocTest<MassTransferBloc, MassTransferState>(
        'SeleccionarUbicacionDestinoMassEvent con origen rechaza selección',
        build: buildBloc,
        seed: () => const MassTransferState(
          status: MassTransferStatus.ready,
          idUbicacionOrigen: 10,
        ),
        act: (bloc) => bloc.add(
          const SeleccionarUbicacionDestinoMassEvent(tUbicacionOrigen),
        ),
        expect: () => [
          const MassTransferState(
            status: MassTransferStatus.ready,
            idUbicacionOrigen: 10,
            ubicacionDestinoValida: false,
            mensajeError: 'La ubicación destino no puede ser la misma de origen',
            failure: InfoRapidaValidationFailure(
              'La ubicación destino no puede ser la misma de origen',
            ),
          ),
        ],
      );

      blocTest<MassTransferBloc, MassTransferState>(
        'EscanearUbicacionDestinoMassEvent selecciona ubicación por barcode',
        build: buildBloc,
        seed: () => const MassTransferState(
          status: MassTransferStatus.ready,
          idUbicacionOrigen: 10,
          ubicacionesDestino: [tUbicacionDestino],
        ),
        act: (bloc) =>
            bloc.add(const EscanearUbicacionDestinoMassEvent('LOC-B1')),
        expect: () => [
          const MassTransferState(
            status: MassTransferStatus.ready,
            idUbicacionOrigen: 10,
            ubicacionesDestino: [tUbicacionDestino],
            ubicacionDestino: tUbicacionDestino,
            ubicacionDestinoValida: true,
          ),
        ],
      );

      blocTest<MassTransferBloc, MassTransferState>(
        'EscanearUbicacionDestinoMassEvent con código inexistente emite error',
        build: buildBloc,
        seed: () => const MassTransferState(
          status: MassTransferStatus.ready,
          idUbicacionOrigen: 10,
          ubicacionesDestino: [tUbicacionDestino],
        ),
        act: (bloc) =>
            bloc.add(const EscanearUbicacionDestinoMassEvent('UNKNOWN')),
        expect: () => [
          const MassTransferState(
            status: MassTransferStatus.ready,
            idUbicacionOrigen: 10,
            ubicacionesDestino: [tUbicacionDestino],
            mensajeError: 'Ubicación con código "unknown" no encontrada',
            failure: InfoRapidaValidationFailure(
              'Ubicación con código "unknown" no encontrada',
            ),
          ),
        ],
      );
    });

    group('Actualizar cantidad y remover ítems', () {
      blocTest<MassTransferBloc, MassTransferState>(
        'ActualizarCantidadItemMassEvent ajusta cantidad e invalida si supera disponible',
        build: buildBloc,
        seed: () => const MassTransferState(
          items: [
            ItemTransferenciaLinea(
              producto: tProducto1,
              cantidadATransferir: 15.0,
              cantidadValida: true,
            ),
          ],
        ),
        act: (bloc) {
          bloc.add(const ActualizarCantidadItemMassEvent(
            productoId: 101,
            loteId: 1,
            cantidad: 20.0, // Superior a 15.0 disponible
          ));
        },
        expect: () => [
          const MassTransferState(
            items: [
              ItemTransferenciaLinea(
                producto: tProducto1,
                cantidadATransferir: 20.0,
                cantidadValida: false,
              ),
            ],
          ),
        ],
      );

      blocTest<MassTransferBloc, MassTransferState>(
        'RemoverItemMassEvent elimina ítem por productoId y loteId',
        build: buildBloc,
        seed: () => const MassTransferState(
          items: [
            ItemTransferenciaLinea(
              producto: tProducto1,
              cantidadATransferir: 15.0,
            ),
            ItemTransferenciaLinea(
              producto: tProducto2,
              cantidadATransferir: 25.0,
            ),
          ],
        ),
        act: (bloc) => bloc.add(const RemoverItemMassEvent(
          productoId: 101,
          loteId: 1,
        )),
        expect: () => [
          const MassTransferState(
            items: [
              ItemTransferenciaLinea(
                producto: tProducto2,
                cantidadATransferir: 25.0,
              ),
            ],
          ),
        ],
      );
    });

    group('ConfirmarTransferenciaMasivaEvent', () {
      blocTest<MassTransferBloc, MassTransferState>(
        'sin ítems emite error de validación sin llamar usecase',
        build: buildBloc,
        seed: () => const MassTransferState(items: []),
        act: (bloc) => bloc.add(const ConfirmarTransferenciaMasivaEvent()),
        expect: () => [
          const MassTransferState(
            items: [],
            mensajeError: 'No hay productos seleccionados para transferir',
            failure: InfoRapidaValidationFailure(
              'No hay productos seleccionados para transferir',
            ),
          ),
        ],
      );

      blocTest<MassTransferBloc, MassTransferState>(
        'sin destino válido emite error de validación',
        build: buildBloc,
        seed: () => const MassTransferState(
          items: [
            ItemTransferenciaLinea(
              producto: tProducto1,
              cantidadATransferir: 10.0,
            ),
          ],
          ubicacionDestinoValida: false,
        ),
        act: (bloc) => bloc.add(const ConfirmarTransferenciaMasivaEvent()),
        expect: () => [
          const MassTransferState(
            items: [
              ItemTransferenciaLinea(
                producto: tProducto1,
                cantidadATransferir: 10.0,
              ),
            ],
            ubicacionDestinoValida: false,
            mensajeError: 'Selecciona una ubicación destino válida',
            failure: InfoRapidaValidationFailure(
              'Selecciona una ubicación destino válida',
            ),
          ),
        ],
      );

      blocTest<MassTransferBloc, MassTransferState>(
        'con cantidad inválida en algún ítem emite error',
        build: buildBloc,
        seed: () => const MassTransferState(
          items: [
            ItemTransferenciaLinea(
              producto: tProducto1,
              cantidadATransferir: 0.0,
              cantidadValida: false,
            ),
          ],
          ubicacionDestino: tUbicacionDestino,
          ubicacionDestinoValida: true,
        ),
        act: (bloc) => bloc.add(const ConfirmarTransferenciaMasivaEvent()),
        expect: () => [
          const MassTransferState(
            items: [
              ItemTransferenciaLinea(
                producto: tProducto1,
                cantidadATransferir: 0.0,
                cantidadValida: false,
              ),
            ],
            ubicacionDestino: tUbicacionDestino,
            ubicacionDestinoValida: true,
            mensajeError:
                'Verifica que todas las cantidades sean mayores a 0 y válidas',
            failure: InfoRapidaValidationFailure(
              'Verifica que todas las cantidades sean mayores a 0 y válidas',
            ),
          ),
        ],
      );

      blocTest<MassTransferBloc, MassTransferState>(
        'con mezcla de distintos propietarios emite PropietarioMismatchFailure',
        build: buildBloc,
        seed: () => const MassTransferState(
          items: [
            ItemTransferenciaLinea(
              producto: tProducto1, // Empresa A
              cantidadATransferir: 10.0,
            ),
            ItemTransferenciaLinea(
              producto: tProductoDistintoPropietario, // Empresa B
              cantidadATransferir: 5.0,
            ),
          ],
          ubicacionDestino: tUbicacionDestino,
          ubicacionDestinoValida: true,
        ),
        act: (bloc) => bloc.add(const ConfirmarTransferenciaMasivaEvent()),
        expect: () => [
          const MassTransferState(
            items: [
              ItemTransferenciaLinea(
                producto: tProducto1,
                cantidadATransferir: 10.0,
              ),
              ItemTransferenciaLinea(
                producto: tProductoDistintoPropietario,
                cantidadATransferir: 5.0,
              ),
            ],
            ubicacionDestino: tUbicacionDestino,
            ubicacionDestinoValida: true,
            mensajeError:
                'No puedes mezclar productos de "Empresa A" con productos de "Empresa B"',
            failure: PropietarioMismatchFailure(
              'No puedes mezclar productos de "Empresa A" con productos de "Empresa B"',
            ),
          ),
        ],
      );

      blocTest<MassTransferBloc, MassTransferState>(
        'confirmación exitosa emite loading y luego success con resultado',
        build: () {
          when(() => mockCrearTransferenciaMasiva(any())).thenAnswer(
            (_) async => const Right(tTransferMasivaResult),
          );
          return buildBloc();
        },
        seed: () => const MassTransferState(
          status: MassTransferStatus.ready,
          idAlmacen: 1,
          idUbicacionOrigen: 10,
          items: [
            ItemTransferenciaLinea(
              producto: tProducto1,
              cantidadATransferir: 10.0,
            ),
            ItemTransferenciaLinea(
              producto: tProducto2,
              cantidadATransferir: 20.0,
            ),
          ],
          ubicacionDestino: tUbicacionDestino,
          ubicacionDestinoValida: true,
          dateStart: '2026-10-08 09:00:00',
        ),
        act: (bloc) => bloc.add(const ConfirmarTransferenciaMasivaEvent()),
        expect: () => [
          isA<MassTransferState>()
              .having((s) => s.status, 'status', MassTransferStatus.loading),
          isA<MassTransferState>()
              .having((s) => s.status, 'status', MassTransferStatus.success)
              .having((s) => s.resultadoTransferencia, 'resultado',
                  tTransferMasivaResult),
        ],
        verify: (_) {
          verify(() => mockCrearTransferenciaMasiva(any())).called(1);
        },
      );

      blocTest<MassTransferBloc, MassTransferState>(
        'confirmación fallida emite loading y luego failure con mensaje de error',
        build: () {
          when(() => mockCrearTransferenciaMasiva(any())).thenAnswer(
            (_) async => const Left(SinConexionFailure('Error en backend')),
          );
          return buildBloc();
        },
        seed: () => const MassTransferState(
          status: MassTransferStatus.ready,
          idAlmacen: 1,
          idUbicacionOrigen: 10,
          items: [
            ItemTransferenciaLinea(
              producto: tProducto1,
              cantidadATransferir: 10.0,
            ),
          ],
          ubicacionDestino: tUbicacionDestino,
          ubicacionDestinoValida: true,
        ),
        act: (bloc) => bloc.add(const ConfirmarTransferenciaMasivaEvent()),
        expect: () => [
          isA<MassTransferState>()
              .having((s) => s.status, 'status', MassTransferStatus.loading),
          isA<MassTransferState>()
              .having((s) => s.status, 'status', MassTransferStatus.failure)
              .having((s) => s.mensajeError, 'mensajeError', 'Error en backend')
              .having((s) => s.failure, 'failure',
                  const SinConexionFailure('Error en backend')),
        ],
      );
    });

    group('LimpiarMensajeMassTransferEvent', () {
      blocTest<MassTransferBloc, MassTransferState>(
        'limpia mensajeError y failure',
        build: buildBloc,
        seed: () => const MassTransferState(
          mensajeError: 'Error',
          failure: InfoRapidaValidationFailure('Error'),
        ),
        act: (bloc) => bloc.add(const LimpiarMensajeMassTransferEvent()),
        expect: () => [
          const MassTransferState(
            mensajeError: null,
            failure: null,
          ),
        ],
      );
    });
  });
}
