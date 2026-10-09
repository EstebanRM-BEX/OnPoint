import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/info_rapida/data/datasources/info_rapida_local_data_source.dart';
import 'package:wms_app/features/info_rapida/data/datasources/info_rapida_remote_data_source.dart';
import 'package:wms_app/features/info_rapida/data/exceptions/info_rapida_exceptions.dart';
import 'package:wms_app/features/info_rapida/data/services/info_rapida_entorno.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';
import 'package:wms_app/features/info_rapida/domain/failures/info_rapida_failures.dart';
import 'package:wms_app/features/info_rapida/domain/repositories/info_rapida_repository.dart';

/// Implementación del repositorio de Información Rápida.
///
/// Coordina las llamadas al backend mediante [InfoRapidaRemoteDataSource],
/// la sincronización local y cachés con [InfoRapidaLocalDataSource] y la
/// información del entorno operativo con [InfoRapidaEntorno].
@LazySingleton(as: InfoRapidaRepository)
class InfoRapidaRepositoryImpl implements InfoRapidaRepository {
  final InfoRapidaRemoteDataSource _remoteDataSource;
  final InfoRapidaLocalDataSource _localDataSource;
  final InfoRapidaEntorno _entorno;

  InfoRapidaRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._entorno,
  );

  Failure _mapException(dynamic e) {
    if (e is DispositivoNoAutorizadoException) {
      return DispositivoNoAutorizadoFailure(e.message);
    }
    if (e is ActualizarVersionException) {
      return ActualizarVersionFailure(e.message);
    }
    if (e is NoEncontradoException) {
      return NoEncontradoFailure(e.message);
    }
    if (e is SessionExpiredException) {
      return SesionExpiradaFailure(e.message);
    }
    if (e is NetworkException) {
      return SinConexionFailure(e.message);
    }
    if (e is ServerException) {
      return ServerFailure(e.message);
    }
    if (e is CacheException) {
      return CacheFailure(e.message);
    }
    return ServerFailure(e.toString());
  }

  // Las consultas no se guardan aquí en "Últimas consultas": lo decide el
  // bloc (las internas, como refrescar tras una transferencia, no van).
  @override
  Future<Either<Failure, InfoRapida>> consultarPorBarcode(String barcode) async {
    if (!await _entorno.hayRed()) {
      return const Left(SinConexionFailure());
    }

    try {
      final deviceId = await _entorno.deviceId();
      final versionApp = await _entorno.versionApp();

      final result = await _remoteDataSource.getInfoQuick(
        barcode: barcode,
        deviceId: deviceId,
        versionApp: versionApp,
      );

      return Right(result);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, InfoRapida>> consultarPorId({
    required int id,
    required bool isProduct,
  }) async {
    if (!await _entorno.hayRed()) {
      return const Left(SinConexionFailure());
    }

    try {
      final deviceId = await _entorno.deviceId();
      final versionApp = await _entorno.versionApp();

      final result = await _remoteDataSource.getInfoQuickManual(
        id: id,
        isProduct: isProduct,
        deviceId: deviceId,
        versionApp: versionApp,
      );

      return Right(result);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<RecentQuery>>> getConsultasRecientes() async {
    try {
      final items = await _localDataSource.getRecentQueries();
      return Right(items);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> guardarConsultaReciente(RecentQuery query) async {
    try {
      await _localDataSource.saveRecentQuery(query);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> borrarConsultasRecientes() async {
    try {
      await _localDataSource.clearRecentQueries();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductoCatalogo>>> buscarCatalogoProductos({
    required String query,
    String? propietario,
    required int limit,
    required int offset,
  }) async {
    try {
      final items = await _localDataSource.buscarCatalogoProductos(
        query: query,
        propietario: propietario,
        limit: limit,
        offset: offset,
      );
      return Right(items);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getPropietariosCatalogo() async {
    try {
      return Right(await _localDataSource.getPropietariosCatalogo());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UbicacionCatalogo>>> getCatalogoUbicaciones({
    bool forceRefresh = false,
  }) async {
    try {
      final items = await _localDataSource.getCatalogoUbicaciones(
        forceRefresh: forceRefresh,
      );
      return Right(items);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> precargarCatalogos() async {
    try {
      await _localDataSource.precargarCatalogos();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConfigInfoRapidaUsuario>> getConfiguracionUsuario({
    int? userId,
  }) async {
    try {
      final config = await _localDataSource.getConfiguracionUsuario(
        userId: userId,
      );
      return Right(config);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductoInfo>> actualizarProducto(
    ActualizarProductoParams params,
  ) async {
    if (!await _entorno.hayRed()) {
      return const Left(SinConexionFailure());
    }

    try {
      final updated = await _remoteDataSource.updateProduct(params);
      await _localDataSource.syncLocalProductUpdated(params);
      return Right(updated);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, UbicacionInfo>> actualizarUbicacion(
    ActualizarUbicacionParams params,
  ) async {
    if (!await _entorno.hayRed()) {
      return const Left(SinConexionFailure());
    }

    try {
      final updated = await _remoteDataSource.updateLocation(params);
      await _localDataSource.syncLocalLocationUpdated(params);
      return Right(updated);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, TransferenciaIndividualResult>>
      crearTransferenciaIndividual(
    CrearTransferenciaIndividualParams params,
  ) async {
    if (!await _entorno.hayRed()) {
      return const Left(SinConexionFailure());
    }

    try {
      final result = await _remoteDataSource.crearTransferenciaIndividual(params);
      return Right(result);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, TransferenciaMasivaResult>> crearTransferenciaMasiva(
    CrearTransferenciaMasivaParams params,
  ) async {
    if (!await _entorno.hayRed()) {
      return const Left(SinConexionFailure());
    }

    try {
      // El legacy vaciaba aquí la tabla de Crear Transferencia y borraba el
      // borrador de otro módulo (bug 2 del plan): no se toca.
      final result = await _remoteDataSource.crearTransferenciaMasiva(params);
      return Right(result);
    } catch (e) {
      return Left(_mapException(e));
    }
  }
}
