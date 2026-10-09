import 'package:fpdart/fpdart.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/features/packaging_types/domain/entities/packaging_type.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';

/// Marca de tiempo del pedido que se envía a Odoo (`update_time_transfer`).
enum MarcaTiempoPack { inicio, fin }

/// Contrato del packing por pedido.
///
/// Las operaciones sobre líneas reciben la entidad completa y la
/// implementación trabaja por su PK ([ProductoPacking.id]), nunca por idMove.
abstract class PackingPedidoRepository {
  // ── Pedidos ───────────────────────────────────────────────────────────────

  /// Trae los pedidos de Odoo y los deja en la base local (limpia lo que ya
  /// no existe y reconcilia cantidades).
  Future<Either<Failure, SyncPedidosPackResult>> syncPedidos({
    required bool isLoadingDialog,
  });

  Future<Either<Failure, List<PedidoPack>>> getPedidosLocal();

  /// Asigna el usuario actual como responsable e inicia el tiempo.
  Future<Either<Failure, PedidoPack>> asignarResponsable(int pedidoId);

  Future<Either<Failure, Unit>> registrarTiempo({
    required int pedidoId,
    required MarcaTiempoPack marca,
  });

  Future<Either<Failure, PedidoPackDetalle>> getPedidoDetalle(int pedidoId);

  /// Consulta el detalle del pedido en el servidor (`transferencias/pack/detail`),
  /// sincroniza sus productos y paquetes localmente y devuelve el [PedidoPackDetalle] actualizado.
  Future<Either<Failure, PedidoPackDetalle>> refrescarDetalleRemoto(
    int pedidoId,
  );

  // ── Escaneo y separación ──────────────────────────────────────────────────

  Future<Either<Failure, List<BarcodeProductoPacking>>> getBarcodesProducto(
    ProductoPacking producto,
  );

  Future<Either<Failure, ProductoPacking>> marcarUbicacionOk(
    ProductoPacking producto,
  );

  /// Producto escaneado: arranca el tiempo de separación con cantidad 0.
  Future<Either<Failure, ProductoPacking>> marcarProductoOk(
    ProductoPacking producto,
  );

  Future<Either<Failure, ProductoPacking>> actualizarCantidadSeparada(
    ProductoPacking producto,
    double cantidad,
  );

  /// Envía la línea a preparar con [cantidad] (completa o parcial con
  /// [novedad]) al servidor y la deja en "Listos". Requiere red.
  Future<Either<Failure, ProductoPacking>> separarProducto({
    required ProductoPacking producto,
    required double cantidad,
    String? novedad,
  });

  /// Envía [cantidad] a preparar y deja el resto como una línea nueva en
  /// "Por hacer" (hay que reescanear ubicación y producto). Misma operación
  /// de servidor que [separarProducto], con una observación fija. Requiere
  /// red.
  Future<Either<Failure, Unit>> dividirProducto({
    required ProductoPacking producto,
    required double cantidad,
  });

  /// Devuelve una línea de "Listos" a "Por hacer". Si venía de una división,
  /// su cantidad se suma a la fila restante.
  Future<Either<Failure, Unit>> deshacerSeparacion(ProductoPacking producto);

  /// Devuelve productos preparados a "Por hacer" vía `transferencias/pack/prepare/cancel`
  /// y sincroniza el detalle completo del pedido en el dispositivo.
  Future<Either<Failure, String>> cancelarPreparados({
    required int pedidoId,
    required List<ProductoPacking> productos,
  });

  // ── Paquetes ──────────────────────────────────────────────────────────────

  Future<Either<Failure, PaquetePacking>> crearPaquete({
    required PedidoPack pedido,
    required List<ProductoPacking> productos,
    required bool certificado,
    required bool isSticker,
    double peso = 0,
    PackagingType? tipoEmpaque,
  });

  Future<Either<Failure, DesempaqueResult>> desempacarProducto({
    required PaquetePacking paquete,
    required ProductoPacking producto,
  });

  /// Elimina la caja completa; sus líneas vuelven a "Por hacer".
  Future<Either<Failure, String>> eliminarPaquete(PaquetePacking paquete);

  /// Cambia el peso de la caja. Devuelve el mensaje de Odoo.
  Future<Either<Failure, String>> editarPesoPaquete({
    required PaquetePacking paquete,
    required double peso,
  });

  Future<Either<Failure, List<UbicacionMuelle>>> getUbicacionesMuelle();

  Future<Either<Failure, String>> asignarUbicacionPaquetes({
    required int pedidoId,
    required List<PaquetePacking> paquetes,
    required UbicacionMuelle ubicacion,
  });

  // ── Cierre ────────────────────────────────────────────────────────────────

  /// Valida el pedido en Odoo. [aceptarVencidos] reintenta aceptando
  /// productos con fecha de caducidad alcanzada.
  Future<Either<Failure, ValidacionPedidoResult>> validarPedido({
    required int pedidoId,
    required bool crearBackorder,
    bool aceptarVencidos = false,
  });

  // ── Temperatura y novedades ───────────────────────────────────────────────

  Future<Either<Failure, TemperaturaIa>> leerTemperaturaIa(String imagePath);

  /// Envía la temperatura; con [imagePath] adjunta la foto del termómetro.
  Future<Either<Failure, ProductoPacking>> enviarTemperatura({
    required ProductoPacking producto,
    required double temperatura,
    String? imagePath,
  });

  Future<Either<Failure, ProductoPacking>> enviarImagenNovedad({
    required ProductoPacking producto,
    required String imagePath,
  });

  // ── Catálogos ─────────────────────────────────────────────────────────────

  Future<Either<Failure, ConfigPackingUsuario>> getConfiguracion();

  Future<Either<Failure, List<Novedad>>> getNovedades();
}
