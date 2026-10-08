// Comportamientos que la fase 4 alineó con el módulo legacy al conectar las
// pantallas (ver docs/plan_migracion_info_rapida.md, fase 4).
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
import 'package:wms_app/features/info_rapida/domain/usecases/actualizar_producto_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/actualizar_ubicacion_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/crear_transferencia_individual_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/crear_transferencia_masiva_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_catalogo_ubicaciones_usecase.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/location/location_info_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/mass_transfer/mass_transfer_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/product/product_info_bloc.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/transfer/transfer_info_bloc.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_url_imagen_producto.dart';

class _MockCrearMasiva extends Mock
    implements CrearTransferenciaMasivaUseCase {}

class _MockCrearIndividual extends Mock
    implements CrearTransferenciaIndividualUseCase {}

class _MockCatalogoUbicaciones extends Mock
    implements GetCatalogoUbicacionesUseCase {}

class _MockActualizarUbicacion extends Mock
    implements ActualizarUbicacionUseCase {}

class _MockActualizarProducto extends Mock
    implements ActualizarProductoUseCase {}

class _MockImagen extends Mock implements GetUrlImagenProducto {}

const _destino = UbicacionCatalogo(
  id: 20,
  name: 'WH/Stock/B1',
  barcode: 'LOC-B1',
  idWarehouse: 7,
  warehouseName: 'Almacén Norte',
);

ProductoUbicacion _prod(
  int id, {
  double mano = 10,
  bool? packing,
  String? propietario,
  String barcode = '',
}) => ProductoUbicacion(
  id: id,
  producto: 'P$id',
  codigoBarras: barcode,
  cantidad: 99,
  cantidadMano: mano,
  loteId: id,
  packing: packing,
  manejoPropietario: propietario != null,
  propietario: propietario,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const GetCatalogoUbicacionesParams());
    registerFallbackValue(
      const CrearTransferenciaMasivaParams(
        dateStart: '',
        dateEnd: '',
        idAlmacen: 0,
        idUbicacionOrigen: 0,
        idUbicacionDestino: 0,
        idOperario: 0,
        fechaTransaccion: '',
        listItems: [],
      ),
    );
    registerFallbackValue(
      const CrearTransferenciaIndividualParams(
        idAlmacen: 0,
        idMove: 0,
        idProducto: 0,
        idLote: 0,
        idUbicacionOrigen: 0,
        cantidadEnviada: 0,
        observacion: '',
      ),
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({'userId': 42}));

  group('MassTransferBloc', () {
    late _MockCrearMasiva crear;
    late _MockCatalogoUbicaciones catalogo;

    setUp(() {
      crear = _MockCrearMasiva();
      catalogo = _MockCatalogoUbicaciones();
      when(
        () => catalogo(any()),
      ).thenAnswer((_) async => const Right([_destino]));
    });

    MassTransferBloc build() => MassTransferBloc(
      crearTransferenciaMasiva: crear,
      getCatalogoUbicaciones: catalogo,
    );

    MassTransferState seeded(List<ProductoUbicacion> productos) =>
        MassTransferState(
          status: MassTransferStatus.ready,
          idUbicacionOrigen: 10,
          items: [
            for (final p in productos)
              ItemTransferenciaLinea(
                producto: p,
                cantidadATransferir: p.cantidadMano,
                cantidadValida: true,
              ),
          ],
          ubicacionesDestino: const [_destino],
        );

    blocTest<MassTransferBloc, MassTransferState>(
      'inicializa con la cantidad a la mano (no la total)',
      build: build,
      act: (b) => b.add(
        MassTransferInicializado(
          idAlmacen: 0,
          idUbicacionOrigen: 10,
          nombreUbicacionOrigen: 'A1',
          productosSeleccionados: [_prod(1, mano: 4)],
        ),
      ),
      verify: (b) => expect(b.state.items.single.cantidadATransferir, 4),
    );

    blocTest<MassTransferBloc, MassTransferState>(
      'AgregarItem agrega un producto escaneado',
      build: build,
      seed: () => seeded([_prod(1)]),
      act: (b) => b.add(AgregarItemMassEvent(_prod(2))),
      verify: (b) => expect(b.state.items.map((i) => i.producto.id), [1, 2]),
    );

    blocTest<MassTransferBloc, MassTransferState>(
      'AgregarItem rechaza duplicados con el mensaje del legacy',
      build: build,
      seed: () => seeded([_prod(1)]),
      act: (b) => b.add(AgregarItemMassEvent(_prod(1))),
      verify: (b) {
        expect(b.state.items, hasLength(1));
        expect(
          b.state.mensajeError,
          'El producto ya se encuentra en la lista de transferencia masiva',
        );
      },
    );

    blocTest<MassTransferBloc, MassTransferState>(
      'AgregarItem rechaza mezclar propietarios',
      build: build,
      seed: () => seeded([_prod(1, propietario: 'A')]),
      act: (b) => b.add(AgregarItemMassEvent(_prod(2, propietario: 'B'))),
      verify: (b) {
        expect(b.state.items, hasLength(1));
        expect(b.state.failure, isA<PropietarioMismatchFailure>());
      },
    );

    blocTest<MassTransferBloc, MassTransferState>(
      'confirmar envía el almacén del destino y time_line 2',
      setUp: () => when(() => crear(any())).thenAnswer(
        (_) async => const Right(TransferenciaMasivaResult(transferenciaId: 1)),
      ),
      build: build,
      seed: () => seeded([_prod(1, mano: 3)]).copyWith(
        idAlmacen: 1,
        ubicacionDestino: () => _destino,
        ubicacionDestinoValida: true,
      ),
      act: (b) => b.add(const ConfirmarTransferenciaMasivaEvent()),
      verify: (_) {
        final params =
            verify(() => crear(captureAny())).captured.single
                as CrearTransferenciaMasivaParams;
        expect(params.idAlmacen, 7);
        expect(params.listItems.single.timeLine, 2);
        expect(params.listItems.single.cantidadEnviada, 3);
      },
    );
  });

  group('TransferInfoBloc', () {
    late _MockCrearIndividual crear;

    setUp(() {
      crear = _MockCrearIndividual();
      when(
        () => crear(any()),
      ).thenAnswer((_) async => const Right(TransferenciaIndividualResult()));
    });

    blocTest<TransferInfoBloc, TransferInfoState>(
      'confirmar manda time_line en segundos y observación "Sin novedad"',
      build: () => TransferInfoBloc(
        crearTransferencia: crear,
        getCatalogoUbicaciones: _MockCatalogoUbicaciones(),
      ),
      seed: () => TransferInfoState(
        status: TransferInfoStatus.ready,
        idUbicacionOrigen: 10,
        cantidadDisponible: 10,
        cantidadATransferir: 2,
        cantidadValida: true,
        ubicacionDestino: _destino,
        ubicacionDestinoValida: true,
        dateStart: DateTime.now()
            .subtract(const Duration(minutes: 2))
            .toIso8601String()
            .replaceFirst('T', ' ')
            .substring(0, 19),
      ),
      act: (b) => b.add(const ConfirmarTransferenciaIndividualEvent()),
      verify: (_) {
        final params =
            verify(() => crear(captureAny())).captured.single
                as CrearTransferenciaIndividualParams;
        expect(params.observacion, 'Sin novedad');
        expect(params.timeLine, greaterThanOrEqualTo(119));
      },
    );
  });

  group('LocationInfoBloc', () {
    blocTest<LocationInfoBloc, LocationInfoState>(
      'seleccionar todos omite empaquetados y sin cantidad a la mano',
      build: () =>
          LocationInfoBloc(actualizarUbicacion: _MockActualizarUbicacion()),
      seed: () => LocationInfoState(
        status: LocationInfoStatus.ready,
        ubicacion: UbicacionInfo(
          id: 10,
          nombre: 'A1',
          productos: [_prod(1, packing: true), _prod(2, mano: 0), _prod(3)],
        ),
      ),
      act: (b) => b.add(const SeleccionarTodosProductosDisponiblesEvent()),
      verify: (b) =>
          expect(b.state.productosSeleccionados.map((p) => p.id), [3]),
    );
  });

  group('LocationInfoBloc seleccionar todos alterna', () {
    LocationInfoState conDosPropietarios({List<ProductoUbicacion>? sel}) =>
        LocationInfoState(
          status: LocationInfoStatus.ready,
          modoSeleccionMasiva: true,
          productosSeleccionados: sel ?? const [],
          ubicacion: UbicacionInfo(
            id: 10,
            nombre: 'A1',
            productos: [
              _prod(1, propietario: 'A'),
              _prod(2, propietario: 'A'),
              _prod(3, propietario: 'B'),
            ],
          ),
        );

    LocationInfoBloc build() =>
        LocationInfoBloc(actualizarUbicacion: _MockActualizarUbicacion());

    blocTest<LocationInfoBloc, LocationInfoState>(
      'con otro propietario en la ubicación igual queda "todos seleccionados"',
      build: build,
      seed: conDosPropietarios,
      act: (b) => b.add(const SeleccionarTodosProductosDisponiblesEvent()),
      verify: (b) {
        expect(b.state.productosSeleccionados.map((p) => p.id), [1, 2]);
        expect(b.state.todosCompatiblesSeleccionados, isTrue);
      },
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'tocar de nuevo deselecciona',
      build: build,
      seed: () => conDosPropietarios(
        sel: [_prod(1, propietario: 'A'), _prod(2, propietario: 'A')],
      ),
      act: (b) => b.add(const SeleccionarTodosProductosDisponiblesEvent()),
      verify: (b) {
        expect(b.state.productosSeleccionados, isEmpty);
        expect(b.state.todosCompatiblesSeleccionados, isFalse);
      },
    );

    blocTest<LocationInfoBloc, LocationInfoState>(
      'con una selección parcial completa los compatibles',
      build: build,
      seed: () => conDosPropietarios(sel: [_prod(2, propietario: 'A')]),
      act: (b) => b.add(const SeleccionarTodosProductosDisponiblesEvent()),
      verify: (b) => expect(
        b.state.productosSeleccionados.map((p) => p.id).toSet(),
        {1, 2},
      ),
    );
  });

  group('ProductInfoBloc', () {
    UbicacionProducto u(int id, {String? caducidad, String? entrada}) =>
        UbicacionProducto(
          idUbicacion: id,
          ubicacion: 'U$id',
          fechaCaducidad: caducidad,
          fechaEntrada: entrada,
        );

    final producto = ProductoInfo(
      id: 1,
      nombre: 'P',
      ubicaciones: [
        u(1, caducidad: '2027-01-01', entrada: '2026-01-01'),
        u(2, caducidad: '2026-06-01', entrada: '2026-05-01'),
      ],
    );

    ProductInfoBloc build() => ProductInfoBloc(
      actualizarProducto: _MockActualizarProducto(),
      getUrlImagenProducto: _MockImagen(),
    );

    blocTest<ProductInfoBloc, ProductInfoState>(
      "'date' ordena por fecha de caducidad",
      build: build,
      act: (b) => b
        ..add(ProductInfoInicializado(producto))
        ..add(
          const OrdenarUbicacionesProductoEvent(
            criterio: 'date',
            ascendente: true,
          ),
        ),
      verify: (b) => expect(
        b.state.ubicacionesFiltradas.map((x) => x.idUbicacion),
        [2, 1],
      ),
    );

    blocTest<ProductInfoBloc, ProductInfoState>(
      "'entrada' ordena por fecha de entrada",
      build: build,
      act: (b) => b
        ..add(ProductInfoInicializado(producto))
        ..add(
          const OrdenarUbicacionesProductoEvent(
            criterio: 'entrada',
            ascendente: true,
          ),
        ),
      verify: (b) => expect(
        b.state.ubicacionesFiltradas.map((x) => x.idUbicacion),
        [1, 2],
      ),
    );
  });
}
