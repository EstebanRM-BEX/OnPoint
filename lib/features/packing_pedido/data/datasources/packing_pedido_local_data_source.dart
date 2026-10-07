import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/packing_pedido/data/datasources/local/packing_pedido_database.dart';
import 'package:wms_app/features/packing_pedido/data/models/packing_api_models.dart';
import 'package:wms_app/features/packing_pedido/data/models/packing_db_mappers.dart';
import 'package:wms_app/features/packing_pedido/data/services/packing_reconciler.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/rules/packing_rules.dart';

/// Acceso a `packing_pedido_v2.db`. Toda operación sobre líneas va por PK y
/// las que tocan varias filas van en una sola transacción.
abstract class PackingPedidoLocalDataSource {
  Future<void> ensureOwner(String owner);

  Future<void> guardarSync(List<PedidoPackApi> pedidos);
  Future<void> sincronizarDetalleRemoto(PedidoPackApi pedido);

  Future<List<PedidoPack>> getPedidos();
  Future<PedidoPack> getPedido(int pedidoId);
  Future<PedidoPack> actualizarPedido(
    int pedidoId,
    Map<String, Object?> campos,
  );
  Future<PedidoPackDetalle> getDetalle(int pedidoId);

  Future<ProductoPacking> getProducto(int id);
  Future<ProductoPacking> actualizarProducto(
    int id,
    Map<String, Object?> campos,
  );
  Future<List<BarcodeProductoPacking>> getBarcodes(int pedidoId, int idProduct);

  /// Inserta [preparados] (lo que Odoo acaba de preparar, normalmente una
  /// fila) como nuevas filas "listo" y descuenta [cantidadEnviada] de
  /// [pendiente] (la fila "por hacer" enviada a preparar): la borra si no
  /// queda nada, o dejar el resto como "por hacer" sin confirmar (como una
  /// división: hay que volver a escanear ubicación y producto).
  ///
  /// Devuelve las filas insertadas con su PK real de SQLite.
  Future<List<ProductoPacking>> aplicarPreparado({
    required ProductoPacking pendiente,
    required List<ProductoPacking> preparados,
    required double cantidadEnviada,
  });

  Future<void> deshacerSeparacion(ProductoPacking producto);

  Future<PaquetePacking> guardarPaqueteCreado({
    required List<ProductoPacking> enviados,
    required PaqueteCreadoApi creado,
    required bool certificado,
  });

  /// Devuelve true si el paquete quedó eliminado.
  Future<bool> aplicarDesempaque({
    required PaquetePacking paquete,
    required ProductoPacking empacada,
    required MovesDevueltosApi respuesta,
  });

  Future<void> aplicarEliminarPaquete({
    required PaquetePacking paquete,
    required MovesDevueltosApi respuesta,
  });

  Future<void> asignarUbicacion(
    List<int> paqueteIds,
    UbicacionMuelle ubicacion,
  );
}

@LazySingleton(as: PackingPedidoLocalDataSource)
class PackingPedidoLocalDataSourceImpl implements PackingPedidoLocalDataSource {
  final PackingPedidoDatabase database;

  PackingPedidoLocalDataSourceImpl(this.database);

  static const _tPedidos = PackingPedidoDatabase.tPedidos;
  static const _tProductos = PackingPedidoDatabase.tProductos;
  static const _tPaquetes = PackingPedidoDatabase.tPaquetes;
  static const _tBarcodes = PackingPedidoDatabase.tBarcodes;

  Future<Database> get _db => database.database;

  Future<T> _guard<T>(String op, Future<T> Function() body) async {
    try {
      return await body();
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException('Error local ($op): $e');
    }
  }

  @override
  Future<void> ensureOwner(String owner) =>
      _guard('ensureOwner', () => database.ensureOwner(owner));

  @override
  Future<void> guardarSync(List<PedidoPackApi> pedidos) => _guard(
    'sync',
    () async => (await _db).transaction(
      (txn) => PackingReconciler.sincronizar(txn, pedidos),
    ),
  );

  @override
  Future<void> sincronizarDetalleRemoto(PedidoPackApi pedido) => _guard(
    'sincronizarDetalleRemoto',
    () async => (await _db).transaction(
      (txn) => PackingReconciler.sincronizarPedido(txn, pedido),
    ),
  );

  // ── Pedidos ───────────────────────────────────────────────────────────────

  @override
  Future<List<PedidoPack>> getPedidos() => _guard('getPedidos', () async {
    final rows = await (await _db).query(_tPedidos, orderBy: 'id');
    return rows.map(PackingDbMappers.pedidoFromRow).toList();
  });

  @override
  Future<PedidoPack> getPedido(int pedidoId) => _guard('getPedido', () async {
    final rows = await (await _db).query(
      _tPedidos,
      where: 'id = ?',
      whereArgs: [pedidoId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const CacheException('No se encontró el pedido');
    }
    return PackingDbMappers.pedidoFromRow(rows.first);
  });

  @override
  Future<PedidoPack> actualizarPedido(
    int pedidoId,
    Map<String, Object?> campos,
  ) => _guard('actualizarPedido', () async {
    await (await _db).update(
      _tPedidos,
      campos,
      where: 'id = ?',
      whereArgs: [pedidoId],
    );
    return getPedido(pedidoId);
  });

  @override
  Future<PedidoPackDetalle> getDetalle(int pedidoId) =>
      _guard('getDetalle', () async {
        final db = await _db;
        final pedido = await getPedido(pedidoId);
        final productos = (await db.query(
          _tProductos,
          where: 'pedido_id = ?',
          whereArgs: [pedidoId],
          orderBy: 'id',
        )).map(PackingDbMappers.productoFromRow).toList();

        final empacados = productos.where((p) => p.isEmpacado).toList();
        final paquetes =
            (await db.query(
              _tPaquetes,
              where: 'pedido_id = ?',
              whereArgs: [pedidoId],
              orderBy: 'id',
            )).map((r) {
              final id = r['id'] as int;
              final dentro = empacados.where((p) => p.idPackage == id).toList();
              return PackingDbMappers.paqueteFromRow(
                r,
                productos: dentro,
              ).copyWith(cantidadProductos: dentro.length);
            }).toList();

        // Por hacer: ordenado por ubicación (las sin ubicación al final).
        final porHacer = productos.where((p) => p.isPorHacer).toList()
          ..sort((a, b) {
            if (a.locationName.isEmpty != b.locationName.isEmpty) {
              return a.locationName.isEmpty ? 1 : -1;
            }
            final c = a.locationName.compareTo(b.locationName);
            return c != 0 ? c : a.id - b.id;
          });

        final barcodes = (await db.query(
          _tBarcodes,
          where: 'pedido_id = ?',
          whereArgs: [pedidoId],
        )).map(PackingDbMappers.barcodeFromRow).toList();

        return PedidoPackDetalle(
          pedido: pedido,
          barcodes: barcodes,
          porHacer: porHacer,
          listos: productos.where((p) => p.isListo).toList(),
          empacados: empacados,
          paquetes: paquetes,
        );
      });

  // ── Productos ─────────────────────────────────────────────────────────────

  @override
  Future<ProductoPacking> getProducto(int id) =>
      _guard('getProducto', () async {
        final rows = await (await _db).query(
          _tProductos,
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw const CacheException(
            'El producto ya no existe en el dispositivo. Actualice el pedido.',
          );
        }
        return PackingDbMappers.productoFromRow(rows.first);
      });

  @override
  Future<ProductoPacking> actualizarProducto(
    int id,
    Map<String, Object?> campos,
  ) => _guard('actualizarProducto', () async {
    final n = await (await _db).update(
      _tProductos,
      campos,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (n == 0) {
      throw const CacheException(
        'El producto ya no existe en el dispositivo. Actualice el pedido.',
      );
    }
    return getProducto(id);
  });

  @override
  Future<List<BarcodeProductoPacking>> getBarcodes(
    int pedidoId,
    int idProduct,
  ) => _guard('getBarcodes', () async {
    final rows = await (await _db).query(
      _tBarcodes,
      where: 'pedido_id = ? AND id_product = ?',
      whereArgs: [pedidoId, idProduct],
    );
    final vistos = <String>{};
    return rows
        .map(PackingDbMappers.barcodeFromRow)
        .where((b) => vistos.add(b.barcode.toLowerCase()))
        .toList();
  });

  @override
  Future<List<ProductoPacking>> aplicarPreparado({
    required ProductoPacking pendiente,
    required List<ProductoPacking> preparados,
    required double cantidadEnviada,
  }) => _guard('aplicarPreparado', () async {
    return (await _db).transaction((txn) async {
      // Relee la fila pendiente dentro de la transacción: si ya no existe
      // (otra operación la consumió) o cambió de cantidad mientras la
      // petición estaba en vuelo, se usa el dato fresco.
      final actual = await _filaEnTxn(txn, pendiente.id);

      // Lo que Odoo acaba de preparar entra como filas nuevas "listo", con
      // su PK real (el bloc la necesita para acciones posteriores, p. ej.
      // enviar la temperatura).
      final insertados = <ProductoPacking>[];
      for (final p in preparados) {
        final row = PackingDbMappers.productoToRow(p);
        final id = await txn.insert(_tProductos, row);
        insertados.add(PackingDbMappers.productoFromRow({...row, 'id': id}));
      }

      // La fila "por hacer" enviada: se borra si Odoo preparó toda la
      // cantidad; si no, el resto queda "por hacer" fresco (hay que
      // reescanear ubicación y producto), igual que al dividir.
      final resto = actual.quantity - cantidadEnviada;
      if (resto <= PackingRules.epsilon) {
        await txn.delete(
          _tProductos,
          where: 'id = ?',
          whereArgs: [pendiente.id],
        );
      } else {
        await txn.update(
          _tProductos,
          {
            'quantity': resto,
            'quantity_separate': 0,
            'estado': EstadoProductoPacking.porHacer.name,
            'certificado': 0,
            'is_product_split': 1,
            'observation': '',
            'location_ok': 0,
            'product_ok': 0,
            'quantity_ok': 0,
            'time_separate_start': null,
            'time_separate': 0,
          },
          where: 'id = ?',
          whereArgs: [pendiente.id],
        );
      }

      return insertados;
    });
  });

  @override
  Future<void> deshacerSeparacion(ProductoPacking producto) => _guard(
    'deshacerSeparacion',
    () async {
      await (await _db).transaction((txn) async {
        final listo = await _filaEnTxn(txn, producto.id);
        if (!listo.isListo) {
          throw const CacheException('El producto ya no está en listos');
        }

        // Si quedó una fila restante de la misma línea, la cantidad se le
        // suma (aunque el operario ya haya empezado a escanearla).
        final restantes = await txn.query(
          _tProductos,
          where:
              'pedido_id = ? AND id_move = ? AND id_product = ? '
              'AND IFNULL(lote_id, 0) = ? '
              'AND IFNULL(barcode_location, \'\') = ? AND estado = ?',
          whereArgs: [
            listo.pedidoId,
            listo.idMove,
            listo.idProduct,
            listo.loteId ?? 0,
            listo.barcodeLocation,
            EstadoProductoPacking.porHacer.name,
          ],
          orderBy: 'id',
          limit: 1,
        );

        if (restantes.isNotEmpty) {
          final resto = PackingDbMappers.productoFromRow(restantes.first);
          await txn.update(
            _tProductos,
            {'quantity': resto.quantity + listo.quantity},
            where: 'id = ?',
            whereArgs: [resto.id],
          );
          await txn.delete(_tProductos, where: 'id = ?', whereArgs: [listo.id]);
          return;
        }

        await txn.update(
          _tProductos,
          {
            'estado': EstadoProductoPacking.porHacer.name,
            'certificado': 0,
            'quantity_separate': 0,
            'observation': '',
            'image_novedad': '',
            'location_ok': 0,
            'product_ok': 0,
            'quantity_ok': 0,
            'time_separate_start': null,
            'time_separate': 0,
          },
          where: 'id = ?',
          whereArgs: [listo.id],
        );
      });
    },
  );

  // ── Paquetes ──────────────────────────────────────────────────────────────

  @override
  Future<PaquetePacking> guardarPaqueteCreado({
    required List<ProductoPacking> enviados,
    required PaqueteCreadoApi creado,
    required bool certificado,
  }) => _guard('guardarPaqueteCreado', () async {
    final paquete = creado.paquete;
    await (await _db).transaction((txn) async {
      await txn.insert(
        _tPaquetes,
        PackingDbMappers.paqueteToRow(paquete),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (creado.filasEmpacadas.isNotEmpty) {
        // Las filas del paquete son las de Odoo (al dividir, el move
        // empacado trae un id nuevo); las locales enviadas se borran.
        for (final p in enviados) {
          await txn.delete(_tProductos, where: 'id = ?', whereArgs: [p.id]);
        }
        for (final f in creado.filasEmpacadas) {
          await txn.insert(_tProductos, PackingDbMappers.productoToRow(f));
        }
      } else {
        // Respuesta sin list_item: se marcan las locales.
        for (final p in enviados) {
          await txn.update(
            _tProductos,
            {
              'estado': EstadoProductoPacking.empacado.name,
              'certificado': certificado ? 1 : 0,
              'quantity_separate': p.cantidadAEnviar,
              'id_package': paquete.id,
              'package_name': paquete.name,
            },
            where: 'id = ?',
            whereArgs: [p.id],
          );
        }
      }

      await txn.rawUpdate(
        'UPDATE $_tPedidos SET is_selected = 1, '
        'numero_paquetes = IFNULL(numero_paquetes, 0) + 1 WHERE id = ?',
        [paquete.pedidoId],
      );
    });
    return paquete;
  });

  @override
  Future<bool> aplicarDesempaque({
    required PaquetePacking paquete,
    required ProductoPacking empacada,
    required MovesDevueltosApi respuesta,
  }) => _guard('aplicarDesempaque', () async {
    return (await _db).transaction((txn) async {
      await PackingReconciler.devolverAPorHacer(
        txn,
        empacada: empacada,
        move: respuesta.moveDe(empacada),
      );

      final quedan =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM $_tProductos WHERE id_package = ? '
              'AND estado = ?',
              [paquete.id, EstadoProductoPacking.empacado.name],
            ),
          ) ??
          0;

      if (respuesta.paqueteEliminado || quedan == 0) {
        await _borrarPaquete(txn, paquete);
        return true;
      }
      await txn.update(
        _tPaquetes,
        {'cantidad_productos': quedan},
        where: 'id = ?',
        whereArgs: [paquete.id],
      );
      return false;
    });
  });

  @override
  Future<void> aplicarEliminarPaquete({
    required PaquetePacking paquete,
    required MovesDevueltosApi respuesta,
  }) => _guard('aplicarEliminarPaquete', () async {
    await (await _db).transaction((txn) async {
      final filas = (await txn.query(
        _tProductos,
        where: 'id_package = ? AND estado = ?',
        whereArgs: [paquete.id, EstadoProductoPacking.empacado.name],
        orderBy: 'id',
      )).map(PackingDbMappers.productoFromRow).toList();

      // Cada move devuelto se cruza con una fila del paquete (producto +
      // lote); una fila no se usa dos veces.
      final usadas = <int>{};
      for (final move in respuesta.moves) {
        final api = PedidoPackApi.productoFromApi(move);
        final fila = filas
            .where(
              (f) =>
                  !usadas.contains(f.id) &&
                  f.idProduct == api.idProduct &&
                  (api.loteId == null || api.loteId == f.loteId),
            )
            .firstOrNull;
        if (fila == null) continue;
        usadas.add(fila.id);
        await PackingReconciler.devolverAPorHacer(
          txn,
          empacada: fila,
          move: move,
        );
      }

      // Filas que la respuesta no mencionó: vuelven con lo local.
      for (final f in filas.where((f) => !usadas.contains(f.id))) {
        await PackingReconciler.devolverAPorHacer(txn, empacada: f);
      }

      await _borrarPaquete(txn, paquete);
    });
  });

  @override
  Future<void> asignarUbicacion(
    List<int> paqueteIds,
    UbicacionMuelle ubicacion,
  ) => _guard('asignarUbicacion', () async {
    final db = await _db;
    final batch = db.batch();
    for (final id in paqueteIds) {
      batch.update(
        _tPaquetes,
        {
          'location_dest_id': ubicacion.id,
          'location_dest_name': ubicacion.name,
          'location_dest_barcode': ubicacion.barcode,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<ProductoPacking> _filaEnTxn(Transaction txn, int id) async {
    final rows = await txn.query(
      _tProductos,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const CacheException(
        'El producto ya no existe en el dispositivo. Actualice el pedido.',
      );
    }
    return PackingDbMappers.productoFromRow(rows.first);
  }

  /// Borra el paquete (y lo que quede dentro) y corre los consecutivos de las
  /// cajas posteriores conservando el resto de sus datos.
  Future<void> _borrarPaquete(Transaction txn, PaquetePacking paquete) async {
    await txn.delete(
      _tProductos,
      where: 'id_package = ? AND estado = ?',
      whereArgs: [paquete.id, EstadoProductoPacking.empacado.name],
    );

    final todos = (await txn.query(
      _tPaquetes,
      where: 'pedido_id = ?',
      whereArgs: [paquete.pedidoId],
    )).map((r) => PackingDbMappers.paqueteFromRow(r)).toList();
    final eliminado =
        todos.where((p) => p.id == paquete.id).firstOrNull ?? paquete;
    for (final p in PackingRules.recalcularConsecutivos(
      todos,
      eliminado: eliminado,
    )) {
      await txn.update(
        _tPaquetes,
        {'consecutivo': p.consecutivo},
        where: 'id = ?',
        whereArgs: [p.id],
      );
    }

    await txn.delete(_tPaquetes, where: 'id = ?', whereArgs: [paquete.id]);
    await txn.rawUpdate(
      'UPDATE $_tPedidos SET numero_paquetes = '
      'MAX(IFNULL(numero_paquetes, 0) - 1, 0) WHERE id = ?',
      [paquete.pedidoId],
    );
  }

  /// Segundos que tomó separar una línea (0 si no hay hora de inicio).
  static double segundosDesde(DateTime? inicio, DateTime ahora) {
    if (inicio == null) return 0;
    final ms = ahora.difference(inicio).inMilliseconds;
    return ms <= 0 ? 0 : ms / 1000.0;
  }
}
