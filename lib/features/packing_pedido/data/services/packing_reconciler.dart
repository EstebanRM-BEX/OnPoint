import 'package:sqflite/sqflite.dart';
import 'package:wms_app/features/packing_pedido/data/datasources/local/packing_pedido_database.dart';
import 'package:wms_app/features/packing_pedido/data/models/packing_api_models.dart';
import 'package:wms_app/features/packing_pedido/data/models/packing_db_mappers.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/rules/packing_rules.dart';

/// Lleva a SQLite lo que dice Odoo sin perder el trabajo local del operario
/// (avance del escaneo en una línea "por hacer" todavía no enviada).
///
/// Odoo es la fuente de verdad de: qué pedidos existen, qué moves tiene cada
/// uno y cuánto queda por hacer, qué está preparado (desde que
/// `transferencias/pack/prepare` pasó a ser quien separa) y qué hay dentro de
/// cada caja. Nada vive solo en el dispositivo salvo el progreso de un
/// escaneo en curso sobre una línea "por hacer".
class PackingReconciler {
  const PackingReconciler._();

  static const _t = PackingPedidoDatabase.tProductos;
  static const _eps = PackingRules.epsilon;

  static final _porHacer = EstadoProductoPacking.porHacer.name;
  static final _listo = EstadoProductoPacking.listo.name;
  static final _empacado = EstadoProductoPacking.empacado.name;

  // ── Sincronización completa ───────────────────────────────────────────────

  static Future<void> sincronizar(
    Transaction txn,
    List<PedidoPackApi> api,
  ) async {
    final ids = api.map((p) => p.pedido.id).toSet();

    // Pedidos que ya no vienen (validados, cancelados o de otro usuario).
    final locales = await txn.query(
      PackingPedidoDatabase.tPedidos,
      columns: ['id'],
    );
    for (final r in locales) {
      final id = r['id'] as int;
      if (!ids.contains(id)) await borrarPedido(txn, id);
    }

    for (final p in api) {
      await _sincronizarPedido(txn, p);
    }
  }

  static Future<void> borrarPedido(Transaction txn, int pedidoId) async {
    for (final t in [
      PackingPedidoDatabase.tBarcodes,
      PackingPedidoDatabase.tProductos,
      PackingPedidoDatabase.tPaquetes,
    ]) {
      await txn.delete(t, where: 'pedido_id = ?', whereArgs: [pedidoId]);
    }
    await txn.delete(
      PackingPedidoDatabase.tPedidos,
      where: 'id = ?',
      whereArgs: [pedidoId],
    );
  }

  static Future<void> _sincronizarPedido(
    Transaction txn,
    PedidoPackApi api,
  ) async {
    final pedidoId = api.pedido.id;

    // Pedido: datos de la API, conservando las marcas locales.
    final previo = await txn.query(
      PackingPedidoDatabase.tPedidos,
      where: 'id = ?',
      whereArgs: [pedidoId],
      limit: 1,
    );
    final row = PackingDbMappers.pedidoToRow(api.pedido);
    if (previo.isNotEmpty) {
      final local = PackingDbMappers.pedidoFromRow(previo.first);
      row['is_selected'] = (local.isSelected || api.pedido.isSelected) ? 1 : 0;
      row['is_started'] = (local.isStarted || api.pedido.isStarted) ? 1 : 0;
      if (api.pedido.startTimeTransfer.isEmpty) {
        row['start_time_transfer'] = local.startTimeTransfer;
      }
    }
    await txn.insert(
      PackingPedidoDatabase.tPedidos,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Barcodes: se reemplazan.
    await txn.delete(
      PackingPedidoDatabase.tBarcodes,
      where: 'pedido_id = ?',
      whereArgs: [pedidoId],
    );
    for (final b in api.barcodes) {
      await txn.insert(
        PackingPedidoDatabase.tBarcodes,
        PackingDbMappers.barcodeToRow(pedidoId, b),
      );
    }

    // Preparados: Odoo manda la lista completa y actual (ya no es trabajo
    // local-only desde que separar/dividir pasó por `pack/prepare`). Si no
    // vino el campo, no se tocan.
    if (api.preparados != null) {
      await txn.delete(
        _t,
        where: 'pedido_id = ? AND estado = ?',
        whereArgs: [pedidoId, _listo],
      );
      for (final p in api.preparados!) {
        await txn.insert(_t, PackingDbMappers.productoToRow(p));
      }
    }

    // Paquetes: Odoo manda. Si no vino el campo, no se tocan.
    if (api.paquetes != null) {
      await txn.delete(
        _t,
        where: 'pedido_id = ? AND estado = ?',
        whereArgs: [pedidoId, _empacado],
      );
      await txn.delete(
        PackingPedidoDatabase.tPaquetes,
        where: 'pedido_id = ?',
        whereArgs: [pedidoId],
      );
      for (final pq in api.paquetes!) {
        await txn.insert(
          PackingPedidoDatabase.tPaquetes,
          PackingDbMappers.paqueteToRow(pq),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        for (final prod in pq.productos) {
          await txn.insert(_t, PackingDbMappers.productoToRow(prod));
        }
      }
    }

    await _reconciliarMoves(txn, pedidoId, api.productos);
  }

  /// Deja una sola fila "por hacer" por move, con la cantidad que manda la
  /// API (ya neta de lo preparado: el backend descuenta `cantidad_preparada`
  /// antes de mandar `lista_productos`).
  static Future<void> _reconciliarMoves(
    Transaction txn,
    int pedidoId,
    List<ProductoPacking> apiMoves,
  ) async {
    final porMove = {for (final m in apiMoves) m.idMove: m};

    final locales = (await txn.query(
      _t,
      where: 'pedido_id = ? AND estado = ?',
      whereArgs: [pedidoId, _porHacer],
      orderBy: 'id',
    )).map(PackingDbMappers.productoFromRow).toList();

    // Filas "por hacer" cuyo move ya no existe en la API (cancelado,
    // reemplazado o ya preparado por completo): el avance local ya no aplica.
    for (final f in locales.where((f) => !porMove.containsKey(f.idMove))) {
      await txn.delete(_t, where: 'id = ?', whereArgs: [f.id]);
    }

    for (final api in apiMoves) {
      final porHacer = (await txn.query(
        _t,
        where: 'pedido_id = ? AND id_move = ? AND estado = ?',
        whereArgs: [pedidoId, api.idMove, _porHacer],
        orderBy: 'id',
      )).map(PackingDbMappers.productoFromRow).toList();

      await _dejarPendiente(txn, api, porHacer, api.quantity);
    }
  }

  /// Deja una sola fila "por hacer" del move con [pendiente]. Conserva la
  /// que tenga avance de escaneo; las demás se borran.
  static Future<void> _dejarPendiente(
    Transaction txn,
    ProductoPacking api,
    List<ProductoPacking> porHacer,
    double pendiente,
  ) async {
    if (pendiente <= _eps) {
      for (final f in porHacer) {
        await txn.delete(_t, where: 'id = ?', whereArgs: [f.id]);
      }
      return;
    }

    if (porHacer.isEmpty) {
      await txn.insert(
        _t,
        PackingDbMappers.productoToRow(api.copyWith(quantity: pendiente)),
      );
      return;
    }

    final ordenadas = [...porHacer]
      ..sort((a, b) {
        final pa = (a.productOk || a.quantitySeparate > 0) ? 0 : 1;
        final pb = (b.productOk || b.quantitySeparate > 0) ? 0 : 1;
        return pa != pb ? pa - pb : a.id - b.id;
      });
    final keep = ordenadas.first;
    await txn.update(
      _t,
      {
        ...PackingDbMappers.productoDatosApi(api),
        'quantity': pendiente,
        if (keep.quantitySeparate > pendiente) 'quantity_separate': pendiente,
        'is_product_split': (porHacer.length > 1 || keep.isProductSplit)
            ? 1
            : 0,
      },
      where: 'id = ?',
      whereArgs: [keep.id],
    );
    for (final f in ordenadas.skip(1)) {
      await txn.delete(_t, where: 'id = ?', whereArgs: [f.id]);
    }
  }

  // ── Devolución a "por hacer" (desempacar / eliminar caja) ─────────────────

  /// Borra la fila [empacada] y deja en "por hacer" lo que Odoo indica en
  /// [move] (`quantity` = total pendiente del move, incluido lo que el
  /// operario ya tenga separado sin empacar).
  ///
  /// Sin [move] se calcula con lo local: lo empacado + lo pendiente.
  static Future<void> devolverAPorHacer(
    Transaction txn, {
    required ProductoPacking empacada,
    Map<String, dynamic>? move,
  }) async {
    final pedidoId = empacada.pedidoId;
    await txn.delete(_t, where: 'id = ?', whereArgs: [empacada.id]);

    final apiFila = move == null
        ? null
        : PedidoPackApi.productoFromApi(move, pedidoId: pedidoId);
    final referencia = apiFila ?? empacada;

    final compatibles = (await txn.query(
      _t,
      where:
          'pedido_id = ? AND estado != ? AND id_product = ? '
          'AND IFNULL(lote_id, 0) = ? AND IFNULL(barcode_location, \'\') = ?',
      whereArgs: [
        pedidoId,
        _empacado,
        referencia.idProduct,
        referencia.loteId ?? 0,
        empacada.barcodeLocation,
      ],
      orderBy: 'id',
    )).map(PackingDbMappers.productoFromRow).toList();

    final listos = compatibles.where((f) => f.isListo).toList();
    final porHacer = compatibles.where((f) => f.isPorHacer).toList();
    final enListo = listos.fold<double>(0, (s, f) => s + f.cantidadAEnviar);

    final double totalPendiente;
    if (apiFila != null && apiFila.quantity > 0) {
      totalPendiente = apiFila.quantity;
    } else {
      final pendienteLocal = porHacer.fold<double>(0, (s, f) => s + f.quantity);
      totalPendiente = empacada.cantidadAEnviar + pendienteLocal + enListo;
    }

    // Todas las filas compatibles pasan al move donde Odoo dejó lo pendiente.
    final idMove = (apiFila != null && apiFila.idMove != 0)
        ? apiFila.idMove
        : (porHacer.isNotEmpty ? porHacer.first.idMove : empacada.idMove);
    for (final f in compatibles.where((f) => f.idMove != idMove)) {
      await txn.update(
        _t,
        {'id_move': idMove},
        where: 'id = ?',
        whereArgs: [f.id],
      );
    }

    final base = apiFila ?? _comoPorHacer(empacada);
    await _dejarPendiente(
      txn,
      ProductoPacking(
        id: 0,
        pedidoId: pedidoId,
        batchId: base.batchId,
        idMove: idMove,
        idProduct: base.idProduct,
        productName: base.productName.isNotEmpty
            ? base.productName
            : empacada.productName,
        productCode: base.productCode,
        barcode: base.barcode,
        loteId: base.loteId,
        loteName: base.loteName,
        expireDate: base.expireDate,
        tracking: base.tracking,
        unidades: base.unidades,
        weight: base.weight,
        idLocation: base.idLocation ?? empacada.idLocation,
        locationName: base.locationName.isNotEmpty
            ? base.locationName
            : empacada.locationName,
        barcodeLocation: base.barcodeLocation.isNotEmpty
            ? base.barcodeLocation
            : empacada.barcodeLocation,
        idLocationDest: base.idLocationDest ?? empacada.idLocationDest,
        locationDestName: base.locationDestName,
        manejaTemperatura: base.manejaTemperatura || empacada.manejaTemperatura,
        quantity: totalPendiente - enListo,
      ),
      porHacer,
      totalPendiente - enListo,
    );
  }

  static ProductoPacking _comoPorHacer(ProductoPacking p) => p.copyWith(
    estado: EstadoProductoPacking.porHacer,
    quantitySeparate: 0,
    certificado: false,
  );
}
