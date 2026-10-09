import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/core/error/failures.dart';
import 'package:wms_app/core/utils/formats_utils.dart';
import 'package:wms_app/features/packaging_types/domain/entities/packaging_type.dart';
import 'package:wms_app/features/packing_pedido/data/datasources/packing_pedido_local_data_source.dart';
import 'package:wms_app/features/packing_pedido/data/datasources/packing_pedido_remote_data_source.dart';
import 'package:wms_app/features/packing_pedido/data/services/packing_entorno.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/failures/packing_failures.dart';
import 'package:wms_app/features/packing_pedido/domain/repositories/packing_pedido_repository.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';

@LazySingleton(as: PackingPedidoRepository)
class PackingPedidoRepositoryImpl implements PackingPedidoRepository {
  final PackingPedidoRemoteDataSource remote;
  final PackingPedidoLocalDataSource local;
  final PackingEntorno entorno;

  PackingPedidoRepositoryImpl(this.remote, this.local, this.entorno);

  static const _sinRed = 'No hay conexión a internet';

  /// Ejecuta [body] convirtiendo las excepciones en [Failure].
  /// Con [requiereRed] falla antes de tocar nada si no hay conexión.
  Future<Either<Failure, T>> _run<T>(
    String op,
    Future<T> Function() body, {
    bool requiereRed = false,
  }) async {
    try {
      if (requiereRed && !await entorno.hayRed()) {
        return const Left(NetworkFailure(_sinRed));
      }
      return Right(await body());
    } on VencidosException catch (e) {
      return Left(PackingVencidosFailure(e.message));
    } on SessionExpiredException catch (e) {
      return Left(SessionExpiredFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e, s) {
      debugPrint('❌ packing_pedido.$op: $e\n$s');
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }

  // ── Pedidos ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, SyncPedidosPackResult>> syncPedidos({
    required bool isLoadingDialog,
  }) => _run('syncPedidos', () async {
    final api = await remote.fetchPedidos(isLoadingDialog: isLoadingDialog);
    await local.ensureOwner(await entorno.owner());
    await local.guardarSync(api.pedidos);
    return SyncPedidosPackResult(
      pedidos: await local.getPedidos(),
      needUpdateVersion: api.updateVersion,
    );
  }, requiereRed: true);

  @override
  Future<Either<Failure, List<PedidoPack>>> getPedidosLocal() =>
      _run('getPedidosLocal', () async {
        await local.ensureOwner(await entorno.owner());
        return local.getPedidos();
      });

  @override
  Future<Either<Failure, PedidoPack>> asignarResponsable(int pedidoId) => _run(
    'asignarResponsable',
    () async {
      final userId = await entorno.userId();
      await remote.asignarResponsable(pedidoId: pedidoId, userId: userId);
      await local.actualizarPedido(pedidoId, {
        'responsable_id': userId,
        'responsable': await entorno.userName(),
        'is_selected': 1,
      });
      // El tiempo de inicio no debe frenar la asignación.
      await registrarTiempo(pedidoId: pedidoId, marca: MarcaTiempoPack.inicio);
      return local.getPedido(pedidoId);
    },
    requiereRed: true,
  );

  @override
  Future<Either<Failure, Unit>> registrarTiempo({
    required int pedidoId,
    required MarcaTiempoPack marca,
  }) => _run('registrarTiempo', () async {
    final hora = formatoFecha(entorno.ahora());
    final campo = marca == MarcaTiempoPack.inicio
        ? 'start_time_transfer'
        : 'end_time_transfer';
    await local.actualizarPedido(pedidoId, {
      campo: hora,
      'is_selected': 1,
      'is_started': 1,
    });
    if (await entorno.hayRed()) {
      await remote.enviarTiempo(pedidoId: pedidoId, campo: campo, hora: hora);
    }
    return unit;
  });

  @override
  Future<Either<Failure, PedidoPackDetalle>> getPedidoDetalle(int pedidoId) =>
      _run('getPedidoDetalle', () => local.getDetalle(pedidoId));

  @override
  Future<Either<Failure, PedidoPackDetalle>> refrescarDetalleRemoto(
    int pedidoId,
  ) => _run(
    'refrescarDetalleRemoto',
    () async {
      final deviceId = await entorno.deviceId();
      final versionApp = await entorno.versionApp();
      final api = await remote.fetchDetallePedido(
        pedidoId: pedidoId,
        deviceId: deviceId,
        versionApp: versionApp,
      );
      await local.ensureOwner(await entorno.owner());
      await local.sincronizarDetalleRemoto(api);
      return local.getDetalle(pedidoId);
    },
    requiereRed: true,
  );

  // ── Escaneo y separación ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<BarcodeProductoPacking>>> getBarcodesProducto(
    ProductoPacking producto,
  ) => _run(
    'getBarcodesProducto',
    () => local.getBarcodes(producto.pedidoId, producto.idProduct),
  );

  @override
  Future<Either<Failure, ProductoPacking>> marcarUbicacionOk(
    ProductoPacking producto,
  ) => _run('marcarUbicacionOk', () async {
    await local.actualizarPedido(producto.pedidoId, {'is_selected': 1});
    return local.actualizarProducto(producto.id, {'location_ok': 1});
  });

  @override
  Future<Either<Failure, ProductoPacking>> marcarProductoOk(
    ProductoPacking producto,
  ) => _run(
    'marcarProductoOk',
    () => local.actualizarProducto(producto.id, {
      'product_ok': 1,
      'quantity_ok': 1,
      'quantity_separate': 0,
      'time_separate_start': entorno.ahora().toIso8601String(),
    }),
  );

  @override
  Future<Either<Failure, ProductoPacking>> actualizarCantidadSeparada(
    ProductoPacking producto,
    double cantidad,
  ) => _run(
    'actualizarCantidadSeparada',
    () =>
        local.actualizarProducto(producto.id, {'quantity_separate': cantidad}),
  );

  @override
  Future<Either<Failure, ProductoPacking>> separarProducto({
    required ProductoPacking producto,
    required double cantidad,
    String? novedad,
  }) => _run(
    'separarProducto',
    () => _preparar(
      producto: producto,
      cantidad: cantidad,
      observacion: (novedad == null || novedad.isEmpty)
          ? 'Sin novedad'
          : novedad,
    ),
    requiereRed: true,
  );

  @override
  Future<Either<Failure, Unit>> dividirProducto({
    required ProductoPacking producto,
    required double cantidad,
  }) => _run('dividirProducto', () async {
    await _preparar(
      producto: producto,
      cantidad: cantidad,
      observacion: 'Producto dividido',
    );
    return unit;
  }, requiereRed: true);

  /// Envía a `transferencias/pack/prepare` y aplica la respuesta local.
  /// Separar (completo o parcial con novedad) y dividir son la misma
  /// operación en el servidor; solo cambia la observación enviada.
  Future<ProductoPacking> _preparar({
    required ProductoPacking producto,
    required double cantidad,
    required String observacion,
  }) async {
    final actual = await local.getProducto(producto.id);
    if (!actual.isPorHacer) {
      throw const CacheException('El producto ya fue separado');
    }

    final idOperario = await entorno.userId();
    final tiempo = PackingPedidoLocalDataSourceImpl.segundosDesde(
      actual.timeSeparateStart,
      entorno.ahora(),
    );
    final respuesta = await remote.prepararProducto(
      pedidoId: actual.pedidoId,
      deviceId: await entorno.deviceId(),
      idOperario: idOperario,
      items: [
        ItemPrepararApi(
          idMove: actual.idMove,
          idProducto: actual.idProduct,
          cantidadAEmpacar: cantidad,
          observacion: observacion,
          timeLine: tiempo > 0 ? tiempo : 2,
          fechaTransaccion: formatoFecha(entorno.ahora()),
          idOperario: idOperario,
        ),
      ],
    );

    try {
      final insertados = await local.aplicarPreparado(
        pendiente: actual,
        preparados: respuesta.creados,
        cantidadEnviada: cantidad,
      );
      if (insertados.isEmpty) {
        throw const ServerException(
          'El servidor no devolvió el producto preparado',
        );
      }
      return insertados.firstWhere(
        (p) => p.idMove == actual.idMove,
        orElse: () => insertados.first,
      );
    } on CacheException catch (e) {
      // Odoo ya preparó el producto: el dispositivo tiene que refrescar.
      throw ServerException(
        'El producto se preparó en el servidor pero no se pudo guardar en '
        'el dispositivo. Actualice el pedido. (${e.message})',
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deshacerSeparacion(ProductoPacking producto) =>
      _run('deshacerSeparacion', () async {
        await local.deshacerSeparacion(producto);
        return unit;
      });

  @override
  Future<Either<Failure, String>> cancelarPreparados({
    required int pedidoId,
    required List<ProductoPacking> productos,
  }) => _run(
    'cancelarPreparados',
    () async {
      final deviceId = await entorno.deviceId();
      final versionApp = await entorno.versionApp();
      final items = [
        for (final p in productos)
          ItemCanceladoPreparadoApi(
            idPreparado: p.idPreparado ?? 0,
            idMove: p.idMove,
          ),
      ];

      final msg = await remote.cancelarPreparados(
        pedidoId: pedidoId,
        deviceId: deviceId,
        items: items,
      );

      final api = await remote.fetchDetallePedido(
        pedidoId: pedidoId,
        deviceId: deviceId,
        versionApp: versionApp,
      );
      await local.ensureOwner(await entorno.owner());
      await local.sincronizarDetalleRemoto(api);

      return msg;
    },
    requiereRed: true,
  );

  // ── Paquetes ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, PaquetePacking>> crearPaquete({
    required PedidoPack pedido,
    required List<ProductoPacking> productos,
    required bool certificado,
    required bool isSticker,
    double peso = 0,
    PackagingType? tipoEmpaque,
  }) => _run('crearPaquete', () async {
    // Se releen las filas: la lista de la pantalla puede estar vieja.
    final actuales = [for (final p in productos) await local.getProducto(p.id)];
    final idOperario = await entorno.userId();
    final fecha = formatoFecha(entorno.ahora());

    final creado = await remote.crearPaquete(
      pedido: pedido,
      esCluster: pedido.esCluster,
      isSticker: isSticker,
      certificado: certificado,
      peso: peso,
      tipoPaqueteId: tipoEmpaque?.id ?? 0,
      tipoPaqueteNombre: tipoEmpaque?.name ?? '',
      items: [
        for (final p in actuales)
          ItemEmpaqueApi(
            idMove: p.idMove,
            idProducto: p.idProduct,
            cantidadEnviada: p.cantidadAEnviar,
            idUbicacionOrigen: p.idLocation ?? 0,
            idUbicacionDestino: p.idLocationDest ?? 0,
            idLote: p.loteId ?? 0,
            idOperario: idOperario,
            fechaTransaccion: fecha,
            timeLine: p.timeSeparate > 0 ? p.timeSeparate : 2,
            observacion: p.observation.isEmpty ? 'Sin novedad' : p.observation,
          ),
      ],
    );

    try {
      return await local.guardarPaqueteCreado(
        enviados: actuales,
        creado: creado,
        certificado: certificado,
      );
    } on CacheException catch (e) {
      // Odoo ya creó la caja: el dispositivo tiene que refrescar.
      throw ServerException(
        'El paquete se creó en el servidor pero no se pudo guardar en el '
        'dispositivo. Actualice el pedido. (${e.message})',
      );
    }
  }, requiereRed: true);

  @override
  Future<Either<Failure, DesempaqueResult>> desempacarProducto({
    required PaquetePacking paquete,
    required ProductoPacking producto,
  }) => _run('desempacarProducto', () async {
    final respuesta = await remote.desempacar(
      pedidoId: paquete.pedidoId,
      paqueteId: paquete.id,
      idMove: producto.idMove,
      idOperario: await entorno.userId(),
    );
    try {
      final eliminado = await local.aplicarDesempaque(
        paquete: paquete,
        empacada: producto,
        respuesta: respuesta,
      );
      return DesempaqueResult(
        mensaje: respuesta.mensaje,
        paqueteEliminado: eliminado,
      );
    } on CacheException {
      return DesempaqueResult(
        mensaje:
            'El producto se desempacó en el servidor, pero no se pudo '
            'reflejar en el dispositivo. Actualice el pedido.',
        desincronizado: true,
      );
    }
  }, requiereRed: true);

  @override
  Future<Either<Failure, String>> eliminarPaquete(PaquetePacking paquete) =>
      _run('eliminarPaquete', () async {
        final respuesta = await remote.eliminarPaquete(
          pedidoId: paquete.pedidoId,
          paqueteId: paquete.id,
        );
        try {
          await local.aplicarEliminarPaquete(
            paquete: paquete,
            respuesta: respuesta,
          );
        } on CacheException {
          throw const ServerException(
            'El paquete se eliminó en el servidor, pero no se pudo reflejar '
            'en el dispositivo. Actualice el pedido.',
          );
        }
        return respuesta.mensaje;
      }, requiereRed: true);

  @override
  Future<Either<Failure, String>> editarPesoPaquete({
    required PaquetePacking paquete,
    required double peso,
  }) => _run('editarPesoPaquete', () async {
    final respuesta = await remote.editarPesoPaquete(
      paqueteId: paquete.id,
      peso: peso,
    );
    try {
      await local.actualizarPesoPaquete(paquete.id, respuesta.peso);
    } on CacheException {
      throw const ServerException(
        'El peso se actualizó en el servidor, pero no se pudo reflejar '
        'en el dispositivo. Actualice el pedido.',
      );
    }
    return respuesta.mensaje;
  }, requiereRed: true);

  @override
  Future<Either<Failure, List<UbicacionMuelle>>> getUbicacionesMuelle() =>
      _run('getUbicacionesMuelle', entorno.ubicacionesMuelle);

  @override
  Future<Either<Failure, String>> asignarUbicacionPaquetes({
    required int pedidoId,
    required List<PaquetePacking> paquetes,
    required UbicacionMuelle ubicacion,
  }) => _run('asignarUbicacionPaquetes', () async {
    final ids = paquetes.map((p) => p.id).toList();
    final msg = await remote.asignarUbicacion(
      pedidoId: pedidoId,
      paqueteIds: ids,
      ubicacionId: ubicacion.id,
    );
    await local.asignarUbicacion(ids, ubicacion);
    return msg;
  }, requiereRed: true);

  // ── Cierre ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, ValidacionPedidoResult>> validarPedido({
    required int pedidoId,
    required bool crearBackorder,
    bool aceptarVencidos = false,
  }) => _run('validarPedido', () async {
    final msg = await remote.validarPedido(
      pedidoId: pedidoId,
      crearBackorder: crearBackorder,
      aceptarVencidos: aceptarVencidos,
    );
    await registrarTiempo(pedidoId: pedidoId, marca: MarcaTiempoPack.fin);
    await local.actualizarPedido(pedidoId, {'is_terminate': 1});
    return ValidacionPedidoResult(
      mensaje: msg.isEmpty ? 'Pedido validado correctamente' : msg,
      conBackorder: crearBackorder,
    );
  }, requiereRed: true);

  // ── Temperatura y novedades ───────────────────────────────────────────────

  @override
  Future<Either<Failure, TemperaturaIa>> leerTemperaturaIa(String imagePath) =>
      _run(
        'leerTemperaturaIa',
        () => remote.leerTemperatura(imagePath),
        requiereRed: true,
      );

  @override
  Future<Either<Failure, ProductoPacking>> enviarTemperatura({
    required ProductoPacking producto,
    required double temperatura,
    String? imagePath,
  }) => _run('enviarTemperatura', () async {
    final url = await remote.enviarTemperatura(
      idMove: producto.idMove,
      temperatura: temperatura,
      imagePath: imagePath,
    );
    return local.actualizarProducto(producto.id, {
      'temperatura': temperatura,
      if (url.isNotEmpty) 'image': url,
    });
  }, requiereRed: true);

  @override
  Future<Either<Failure, ProductoPacking>> enviarImagenNovedad({
    required ProductoPacking producto,
    required String imagePath,
  }) => _run('enviarImagenNovedad', () async {
    final url = await remote.enviarImagenNovedad(
      idMove: producto.idMove,
      imagePath: imagePath,
    );
    return local.actualizarProducto(producto.id, {'image_novedad': url});
  }, requiereRed: true);

  // ── Catálogos ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, ConfigPackingUsuario>> getConfiguracion() =>
      _run('getConfiguracion', entorno.configuracion);

  @override
  Future<Either<Failure, List<Novedad>>> getNovedades() =>
      _run('getNovedades', entorno.novedades);
}
