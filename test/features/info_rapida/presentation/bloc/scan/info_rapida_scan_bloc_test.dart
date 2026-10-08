import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/borrar_consultas_recientes_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/consultar_por_barcode_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/consultar_por_id_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_configuracion_usuario_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/get_consultas_recientes_usecase.dart';
import 'package:wms_app/features/info_rapida/domain/usecases/guardar_consulta_reciente_usecase.dart';
import 'package:wms_app/features/info_rapida/presentation/bloc/scan/info_rapida_scan_bloc.dart';

class MockConsultarPorBarcodeUseCase extends Mock
    implements ConsultarPorBarcodeUseCase {}

class MockConsultarPorIdUseCase extends Mock implements ConsultarPorIdUseCase {}

class MockGetConsultasRecientesUseCase extends Mock
    implements GetConsultasRecientesUseCase {}

class MockGuardarConsultaRecienteUseCase extends Mock
    implements GuardarConsultaRecienteUseCase {}

class MockBorrarConsultasRecientesUseCase extends Mock
    implements BorrarConsultasRecientesUseCase {}

class MockGetConfiguracionUsuarioUseCase extends Mock
    implements GetConfiguracionUsuarioUseCase {}

void main() {
  late MockConsultarPorBarcodeUseCase mockConsultarPorBarcode;
  late MockConsultarPorIdUseCase mockConsultarPorId;
  late MockGetConsultasRecientesUseCase mockGetConsultasRecientes;
  late MockGuardarConsultaRecienteUseCase mockGuardarConsultaReciente;
  late MockBorrarConsultasRecientesUseCase mockBorrarConsultasRecientes;
  late MockGetConfiguracionUsuarioUseCase mockGetConfiguracionUsuario;

  final tProducto = const ProductoInfo(
    id: 1,
    nombre: 'Tuerca 1/4',
    referencia: 'TU-14',
    codigoBarras: '770001',
    cantidadDisponible: 100.0,
    unidadMedida: 'un.',
    ubicaciones: [],
  );

  final tUbicacion = const UbicacionInfo(
    id: 10,
    nombre: 'A-01',
    codigoBarras: 'LOC-A01',
    nombreAlmacen: 'Central',
    ubicacionPadre: 'Stock',
    numeroProductos: 5,
    productos: [],
  );

  final tRecentQueryBarcode = RecentQuery(
    query: '770001',
    isManual: false,
    isProduct: true,
    type: 'product',
    title: 'Tuerca 1/4',
    subtitle: 'TU-14',
    date: DateTime(2026, 1, 1),
  );

  final tRecentQueryManual = RecentQuery(
    query: '1',
    isManual: true,
    isProduct: true,
    type: 'product',
    title: 'Tuerca 1/4',
    subtitle: 'TU-14',
    date: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(
      const ConsultarPorBarcodeParams(barcode: 'dummy'),
    );
    registerFallbackValue(
      const ConsultarPorIdParams(id: 1, isProduct: true),
    );
    registerFallbackValue(
      GuardarConsultaRecienteParams(
        query: RecentQuery(
          query: 'dummy',
          isManual: false,
          isProduct: true,
          type: 'product',
          title: 'dummy',
          subtitle: 'dummy',
          date: DateTime.now(),
        ),
      ),
    );
    registerFallbackValue(const GetConfiguracionUsuarioParams());
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockConsultarPorBarcode = MockConsultarPorBarcodeUseCase();
    mockConsultarPorId = MockConsultarPorIdUseCase();
    mockGetConsultasRecientes = MockGetConsultasRecientesUseCase();
    mockGuardarConsultaReciente = MockGuardarConsultaRecienteUseCase();
    mockBorrarConsultasRecientes = MockBorrarConsultasRecientesUseCase();
    mockGetConfiguracionUsuario = MockGetConfiguracionUsuarioUseCase();
  });

  InfoRapidaScanBloc buildBloc() {
    return InfoRapidaScanBloc(
      consultarPorBarcode: mockConsultarPorBarcode,
      consultarPorId: mockConsultarPorId,
      getConsultasRecientes: mockGetConsultasRecientes,
      guardarConsultaReciente: mockGuardarConsultaReciente,
      borrarConsultasRecientes: mockBorrarConsultasRecientes,
      getConfiguracionUsuario: mockGetConfiguracionUsuario,
    );
  }

  group('InfoRapidaScanBloc', () {
    test('estado inicial correcto', () {
      final bloc = buildBloc();
      expect(bloc.state, const InfoRapidaScanState());
      bloc.close();
    });

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'InfoRapidaScanIniciado carga configuración y consultas recientes',
      setUp: () {
        when(() => mockGetConfiguracionUsuario(any())).thenAnswer(
          (_) async => const Right(ConfigInfoRapidaUsuario(
            updateItemInventory: true,
            updateLocationInventory: true,
          )),
        );
        when(() => mockGetConsultasRecientes(any())).thenAnswer(
          (_) async => Right([tRecentQueryBarcode]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const InfoRapidaScanIniciado()),
      expect: () => [
        InfoRapidaScanState(
          configuracion: const ConfigInfoRapidaUsuario(
            updateItemInventory: true,
            updateLocationInventory: true,
          ),
          consultasRecientes: [tRecentQueryBarcode],
        ),
      ],
      verify: (_) {
        verify(() => mockGetConfiguracionUsuario(any())).called(1);
        verify(() => mockGetConsultasRecientes(any())).called(1);
      },
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'ConsultarPorBarcodeEvent exitoso emite loading y luego success con ProductoInfo',
      setUp: () {
        when(() => mockConsultarPorBarcode(any())).thenAnswer(
          (_) async => Right(tProducto),
        );
        when(() => mockGuardarConsultaReciente(any())).thenAnswer(
          (_) async => const Right(unit),
        );
        when(() => mockGetConsultasRecientes(any())).thenAnswer(
          (_) async => Right([tRecentQueryBarcode]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsultarPorBarcodeEvent('  770001  ')),
      expect: () => [
        const InfoRapidaScanState(
          status: InfoRapidaScanStatus.loading,
          ultimoBarcodeConsultado: '770001',
        ),
        InfoRapidaScanState(
          status: InfoRapidaScanStatus.success,
          ultimoBarcodeConsultado: '770001',
          resultado: tProducto,
          consultasRecientes: [tRecentQueryBarcode],
        ),
      ],
      verify: (_) {
        verify(
          () => mockConsultarPorBarcode(
            const ConsultarPorBarcodeParams(barcode: '770001'),
          ),
        ).called(1);
        verify(() => mockGuardarConsultaReciente(any())).called(1);
      },
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'ConsultarPorBarcodeEvent exitoso emite loading y luego success con UbicacionInfo',
      setUp: () {
        when(() => mockConsultarPorBarcode(any())).thenAnswer(
          (_) async => Right(tUbicacion),
        );
        when(() => mockGuardarConsultaReciente(any())).thenAnswer(
          (_) async => const Right(unit),
        );
        when(() => mockGetConsultasRecientes(any())).thenAnswer(
          (_) async => const Right([]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsultarPorBarcodeEvent('LOC-A01')),
      expect: () => [
        const InfoRapidaScanState(
          status: InfoRapidaScanStatus.loading,
          ultimoBarcodeConsultado: 'LOC-A01',
        ),
        InfoRapidaScanState(
          status: InfoRapidaScanStatus.success,
          ultimoBarcodeConsultado: 'LOC-A01',
          resultado: tUbicacion,
          consultasRecientes: const [],
        ),
      ],
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'ConsultarPorBarcodeEvent con código vacío no emite ningún cambio',
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsultarPorBarcodeEvent('   ')),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockConsultarPorBarcode(any()));
      },
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'ConsultarPorBarcodeEvent con fallo emite status failure',
      setUp: () {
        when(() => mockConsultarPorBarcode(any())).thenAnswer(
          (_) async => const Left(NoEncontradoFailure('No encontrado')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsultarPorBarcodeEvent('999999')),
      expect: () => [
        const InfoRapidaScanState(
          status: InfoRapidaScanStatus.loading,
          ultimoBarcodeConsultado: '999999',
        ),
        const InfoRapidaScanState(
          status: InfoRapidaScanStatus.failure,
          ultimoBarcodeConsultado: '999999',
          mensajeError: 'No encontrado',
          failure: NoEncontradoFailure('No encontrado'),
        ),
      ],
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'ConsultarPorBarcodeEvent con error 403 emite DispositivoNoAutorizadoFailure',
      setUp: () {
        when(() => mockConsultarPorBarcode(any())).thenAnswer(
          (_) async => const Left(DispositivoNoAutorizadoFailure()),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsultarPorBarcodeEvent('123456')),
      expect: () => [
        const InfoRapidaScanState(
          status: InfoRapidaScanStatus.loading,
          ultimoBarcodeConsultado: '123456',
        ),
        const InfoRapidaScanState(
          status: InfoRapidaScanStatus.failure,
          ultimoBarcodeConsultado: '123456',
          mensajeError: 'Dispositivo no autorizado',
          failure: DispositivoNoAutorizadoFailure(),
        ),
      ],
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'ConsultarPorIdEvent exitoso emite loading y success',
      setUp: () {
        when(() => mockConsultarPorId(any())).thenAnswer(
          (_) async => Right(tProducto),
        );
        when(() => mockGuardarConsultaReciente(any())).thenAnswer(
          (_) async => const Right(unit),
        );
        when(() => mockGetConsultasRecientes(any())).thenAnswer(
          (_) async => const Right([]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsultarPorIdEvent(
        id: 1,
        isProduct: true,
      )),
      expect: () => [
        const InfoRapidaScanState(
          status: InfoRapidaScanStatus.loading,
        ),
        InfoRapidaScanState(
          status: InfoRapidaScanStatus.success,
          resultado: tProducto,
          consultasRecientes: const [],
        ),
      ],
      verify: (_) {
        verify(
          () => mockConsultarPorId(
            const ConsultarPorIdParams(
              id: 1,
              isProduct: true,
            ),
          ),
        ).called(1);
      },
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'ConsultaRecienteSeleccionada manual ejecuta consulta por ID',
      setUp: () {
        when(() => mockConsultarPorId(any())).thenAnswer(
          (_) async => Right(tProducto),
        );
        when(() => mockGuardarConsultaReciente(any())).thenAnswer(
          (_) async => const Right(unit),
        );
        when(() => mockGetConsultasRecientes(any())).thenAnswer(
          (_) async => const Right([]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ConsultaRecienteSeleccionada(tRecentQueryManual)),
      expect: () => [
        const InfoRapidaScanState(
          status: InfoRapidaScanStatus.loading,
        ),
        InfoRapidaScanState(
          status: InfoRapidaScanStatus.success,
          resultado: tProducto,
          consultasRecientes: const [],
        ),
      ],
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'ConsultaRecienteSeleccionada escaneada ejecuta consulta por barcode',
      setUp: () {
        when(() => mockConsultarPorBarcode(any())).thenAnswer(
          (_) async => Right(tProducto),
        );
        when(() => mockGuardarConsultaReciente(any())).thenAnswer(
          (_) async => const Right(unit),
        );
        when(() => mockGetConsultasRecientes(any())).thenAnswer(
          (_) async => const Right([]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(ConsultaRecienteSeleccionada(tRecentQueryBarcode)),
      expect: () => [
        const InfoRapidaScanState(
          status: InfoRapidaScanStatus.loading,
          ultimoBarcodeConsultado: '770001',
        ),
        InfoRapidaScanState(
          status: InfoRapidaScanStatus.success,
          ultimoBarcodeConsultado: '770001',
          resultado: tProducto,
          consultasRecientes: const [],
        ),
      ],
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'BorrarHistorialConsultasEvent limpia el historial local',
      setUp: () {
        when(() => mockBorrarConsultasRecientes(any())).thenAnswer(
          (_) async => const Right(unit),
        );
      },
      build: buildBloc,
      seed: () => InfoRapidaScanState(consultasRecientes: [tRecentQueryBarcode]),
      act: (bloc) => bloc.add(const BorrarHistorialConsultasEvent()),
      expect: () => [
        const InfoRapidaScanState(consultasRecientes: []),
      ],
      verify: (_) {
        verify(() => mockBorrarConsultasRecientes(any())).called(1);
      },
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'LimpiarResultadoScanEvent resetea el resultado a initial',
      build: buildBloc,
      seed: () => InfoRapidaScanState(
        status: InfoRapidaScanStatus.success,
        resultado: tProducto,
      ),
      act: (bloc) => bloc.add(const LimpiarResultadoScanEvent()),
      expect: () => [
        const InfoRapidaScanState(
          status: InfoRapidaScanStatus.initial,
          resultado: null,
          mensajeError: null,
          failure: null,
        ),
      ],
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'ConsultarPorIdEvent con guardarEnRecientes false no toca el historial',
      setUp: () {
        when(
          () => mockConsultarPorId(any()),
        ).thenAnswer((_) async => Right(tProducto));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ConsultarPorIdEvent(
        id: 1,
        isProduct: true,
        guardarEnRecientes: false,
      )),
      expect: () => [
        const InfoRapidaScanState(status: InfoRapidaScanStatus.loading),
        InfoRapidaScanState(
          status: InfoRapidaScanStatus.success,
          resultado: tProducto,
        ),
      ],
      verify: (_) {
        verifyNever(() => mockGuardarConsultaReciente(any()));
        verifyNever(() => mockGetConsultasRecientes(any()));
      },
    );

    blocTest<InfoRapidaScanBloc, InfoRapidaScanState>(
      'RecargarConsultasRecientesEvent trae lo guardado por otras pantallas',
      setUp: () {
        when(() => mockGetConsultasRecientes(any()))
            .thenAnswer((_) async => Right([tRecentQueryBarcode]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const RecargarConsultasRecientesEvent()),
      expect: () => [
        InfoRapidaScanState(consultasRecientes: [tRecentQueryBarcode]),
      ],
    );
  });
}
