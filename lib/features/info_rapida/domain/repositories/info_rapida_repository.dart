import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/info_rapida/domain/entities/catalogo_info.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida_params.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';
import 'package:wms_app/features/info_rapida/domain/entities/transfer_results.dart';

/// Contrato del repositorio para el módulo de Información Rápida.
///
/// Define las operaciones de consulta polimórfica (Producto, Ubicación, Paquete),
/// gestión de consultas recientes, sincronización/lectura de catálogos locales,
/// configuración de usuario, actualización de entidades y creación de transferencias.
abstract class InfoRapidaRepository {
  /// Consulta información rápida a partir de un código de barras escaneado o ingresado.
  /// Puede retornar un [ProductoInfo], [UbicacionInfo] o [PaqueteInfo].
  Future<Either<Failure, InfoRapida>> consultarPorBarcode(String barcode);

  /// Consulta información rápida de forma manual pasando el ID y si es producto o ubicación.
  Future<Either<Failure, InfoRapida>> consultarPorId({
    required int id,
    required bool isProduct,
  });

  /// Obtiene la lista de consultas recientes del usuario en la base de datos de la empresa actual.
  Future<Either<Failure, List<RecentQuery>>> getConsultasRecientes();

  /// Guarda una nueva consulta en el historial reciente (desduplica y mantiene el límite máximo).
  Future<Either<Failure, Unit>> guardarConsultaReciente(RecentQuery query);

  /// Borra todo el historial de consultas recientes de la empresa actual.
  Future<Either<Failure, Unit>> borrarConsultasRecientes();

  /// Obtiene el catálogo de productos únicos para búsqueda predictiva en Información Rápida.
  Future<Either<Failure, List<ProductoCatalogo>>> getCatalogoProductos({
    bool forceRefresh = false,
  });

  /// Obtiene el catálogo de ubicaciones para búsqueda predictiva y selección en Información Rápida.
  Future<Either<Failure, List<UbicacionCatalogo>>> getCatalogoUbicaciones({
    bool forceRefresh = false,
  });

  /// Obtiene las configuraciones del usuario para visualización/edición de información rápida.
  Future<Either<Failure, ConfigInfoRapidaUsuario>> getConfiguracionUsuario({
    int? userId,
  });

  /// Actualiza los atributos básicos de un producto en el backend y refresca la base local.
  Future<Either<Failure, ProductoInfo>> actualizarProducto(
    ActualizarProductoParams params,
  );

  /// Actualiza el nombre y código de barras de una ubicación en el backend y refresca la base local.
  Future<Either<Failure, UbicacionInfo>> actualizarUbicacion(
    ActualizarUbicacionParams params,
  );

  /// Crea una transferencia individual directa de un producto entre dos ubicaciones.
  Future<Either<Failure, TransferenciaIndividualResult>> crearTransferenciaIndividual(
    CrearTransferenciaIndividualParams params,
  );

  /// Crea una transferencia masiva de múltiples productos desde la ubicación origen actual.
  Future<Either<Failure, TransferenciaMasivaResult>> crearTransferenciaMasiva(
    CrearTransferenciaMasivaParams params,
  );
}
