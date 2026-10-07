import 'package:wms_app/features/packing_pedido/data/models/odoo_parse.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';

/// Pedido tal como llega de `transferencias/pack`, con sus líneas, paquetes
/// y barcodes ya convertidos a entidades. Las líneas traen `id = 0`: la PK
/// la asigna SQLite al insertarlas.
class PedidoPackApi {
  final PedidoPack pedido;
  final List<ProductoPacking> productos;

  /// null si la API no mandó `lista_paquetes`: no se asume que no hay cajas.
  final List<PaquetePacking>? paquetes;
  final List<BarcodeProductoPacking> barcodes;

  const PedidoPackApi({
    required this.pedido,
    required this.productos,
    required this.paquetes,
    required this.barcodes,
  });

  factory PedidoPackApi.fromMap(Map<String, dynamic> json) {
    final id = OdooParse.integer(json['id']) ?? 0;
    final pedido = PedidoPack(
      id: id,
      batchId: OdooParse.integer(json['batch_id']),
      name: OdooParse.str(json['name']),
      referencia: OdooParse.str(json['referencia']),
      contactoName: OdooParse.str(json['contacto_name']),
      observacion: OdooParse.str(json['observacion']),
      fechaCreacion: OdooParse.date(json['fecha_creacion']),
      configPacking: OdooParse.str(json['config_packing']),
      priority: OdooParse.str(json['priority']).isEmpty
          ? '0'
          : OdooParse.str(json['priority']),
      state: OdooParse.str(json['state']),
      pickingType: OdooParse.str(json['picking_type']),
      locationId: OdooParse.integer(json['location_id']),
      locationName: OdooParse.str(json['location_name']),
      locationBarcode: OdooParse.str(json['location_barcode']),
      locationDestId: OdooParse.integer(json['location_dest_id']),
      locationDestName: OdooParse.str(json['location_dest_name']),
      locationDestBarcode: OdooParse.str(json['location_dest_barcode']),
      warehouseId: OdooParse.integer(json['warehouse_id']),
      warehouseName: OdooParse.str(json['warehouse_name']),
      locationNameCluster: OdooParse.str(json['location_name_cluster']),
      locationBarcodeCluster: OdooParse.str(json['location_barcode_cluster']),
      proveedor: OdooParse.str(json['proveedor']),
      propietario: OdooParse.str(json['propietario']),
      manejoPropietario: OdooParse.boolean(json['manejo_propietario']),
      cantidadProductos: OdooParse.integer(json['cantidad_productos']) ?? 0,
      responsableId: OdooParse.integer(json['responsable_id']),
      responsable: OdooParse.str(json['responsable']),
      backorderId: OdooParse.integer(json['backorder_id']),
      backorderName: OdooParse.str(json['backorder_name']),
      createBackorder: OdooParse.str(json['create_backorder']),
      numeroLineas: OdooParse.integer(json['numero_lineas']) ?? 0,
      numeroItems: OdooParse.dbl(json['numero_items']),
      numeroPaquetes: OdooParse.integer(json['numero_paquetes']) ?? 0,
      orderTms: OdooParse.str(json['order_tms']),
      zonaEntrega: OdooParse.str(json['zona_entrega']),
      zonaEntregaTms: OdooParse.str(json['zona_entrega_tms']),
      startTimeTransfer: OdooParse.str(json['start_time_transfer']),
      endTimeTransfer: OdooParse.str(json['end_time_transfer']),
      isSelected: OdooParse.boolean(json['is_selected']),
      isStarted: OdooParse.boolean(json['is_started']),
      isTerminate: OdooParse.boolean(json['is_terminate']),
    );

    final productosJson = OdooParse.maps(json['lista_productos']);
    final productos = [
      for (final p in productosJson) productoFromApi(p, pedidoId: id),
    ];

    final barcodes = <BarcodeProductoPacking>[];
    for (final p in productosJson) {
      for (final b in [
        ...OdooParse.maps(p['product_packing']),
        ...OdooParse.maps(p['other_barcode']),
      ]) {
        final code = OdooParse.str(b['barcode']);
        final idProduct =
            OdooParse.integer(b['id_product']) ??
            OdooParse.integer(p['id_product']);
        if (code.isEmpty || idProduct == null) continue;
        barcodes.add(
          BarcodeProductoPacking(
            idMove:
                OdooParse.integer(b['id_move']) ??
                OdooParse.integer(p['id_move']) ??
                0,
            idProduct: idProduct,
            barcode: code,
            cantidad: OdooParse.dbl(b['cantidad']) > 0
                ? OdooParse.dbl(b['cantidad'])
                : 1,
          ),
        );
      }
    }

    final paquetes = json['lista_paquetes'] is List
        ? [
            for (final pq in OdooParse.maps(json['lista_paquetes']))
              paqueteFromApi(pq, pedidoId: id),
          ]
        : null;

    return PedidoPackApi(
      pedido: pedido,
      productos: productos,
      paquetes: paquetes,
      barcodes: barcodes,
    );
  }

  /// Línea de `lista_productos` (por hacer) o un stock.move de las respuestas
  /// de empaque/desempaque. Con [paquete], la línea queda empacada en él.
  static ProductoPacking productoFromApi(
    Map<String, dynamic> json, {
    int? pedidoId,
    PaquetePacking? paquete,
    bool certificado = true,
  }) {
    // lote_id llega como entero en lista_productos y como [id, nombre] dentro
    // de los paquetes; el nombre viene en lot_id o en el propio lote_id.
    final loteRaw = json['lote_id'];
    final loteId = OdooParse.integer(loteRaw);
    final loteName = OdooParse.refName(json['lot_id']).isNotEmpty
        ? OdooParse.refName(json['lot_id'])
        : OdooParse.refName(loteRaw);

    final quantity = OdooParse.dbl(json['quantity']);
    final empacado = paquete != null;

    return ProductoPacking(
      id: 0,
      pedidoId:
          OdooParse.integer(json['pedido_id']) ??
          pedidoId ??
          paquete?.pedidoId ??
          0,
      batchId: OdooParse.integer(json['batch_id']),
      idMove: OdooParse.integer(json['id_move']) ?? 0,
      idProduct:
          OdooParse.integer(json['id_product']) ??
          OdooParse.refId(json['product_id']) ??
          0,
      productName: OdooParse.refName(json['product_id']).isNotEmpty
          ? OdooParse.refName(json['product_id'])
          : OdooParse.str(json['product_name']),
      productCode: OdooParse.str(json['product_code']),
      barcode: OdooParse.str(json['barcode']),
      loteId: (loteId == null || loteId == 0) ? null : loteId,
      loteName: loteName,
      expireDate: OdooParse.str(json['expire_date']),
      tracking: OdooParse.str(json['tracking']),
      unidades: OdooParse.str(json['unidades']),
      weight: OdooParse.dbl(json['weight']),
      idLocation: OdooParse.refId(json['location_id']),
      locationName: OdooParse.refName(json['location_id']),
      barcodeLocation: OdooParse.str(json['barcode_location']),
      idLocationDest: OdooParse.refId(json['location_dest_id']),
      locationDestName: OdooParse.refName(json['location_dest_id']),
      quantity: quantity,
      quantitySeparate: empacado
          ? (OdooParse.dbl(json['quantity_separate']) > 0
                ? OdooParse.dbl(json['quantity_separate'])
                : quantity)
          : 0,
      estado: empacado
          ? EstadoProductoPacking.empacado
          : EstadoProductoPacking.porHacer,
      certificado:
          empacado &&
          (json.containsKey('is_certificate')
              ? OdooParse.boolean(json['is_certificate'])
              : certificado),
      idPackage: paquete?.id,
      packageName: paquete?.name ?? '',
      observation: empacado ? OdooParse.str(json['observation']) : '',
      manejaTemperatura: OdooParse.boolean(json['maneja_temperatura']),
      temperatura: OdooParse.dbl(json['temperatura']),
      image: OdooParse.str(json['image']),
      imageNovedad: OdooParse.str(json['image_novedad']),
      timeSeparate: OdooParse.dbl(json['time_separate'] ?? json['time']),
    );
  }

  static PaquetePacking paqueteFromApi(
    Map<String, dynamic> json, {
    required int pedidoId,
  }) {
    final base = PaquetePacking(
      id: OdooParse.integer(json['id']) ?? 0,
      pedidoId: OdooParse.integer(json['pedido_id']) ?? pedidoId,
      batchId: OdooParse.integer(json['batch_id']),
      name: OdooParse.str(json['name']),
      packingBarcode: OdooParse.str(json['packing_barcode']),
      consecutivo: OdooParse.str(json['consecutivo']),
      cantidadProductos: OdooParse.integer(json['cantidad_productos']) ?? 0,
      isSticker: OdooParse.boolean(json['is_sticker']),
      isCertificate: OdooParse.boolean(json['is_certificate']),
      typePaquete: OdooParse.str(json['type_paquete']),
      peso: OdooParse.dbl(json['peso'] ?? json['peso_caja']),
      locationDestId: OdooParse.integer(json['location_dest_id']),
      locationDestName: OdooParse.str(json['location_dest_name']),
      locationDestBarcode: OdooParse.str(json['location_dest_barcode']),
    );
    return base.copyWith(
      productos: [
        for (final p in OdooParse.maps(json['lista_productos_in_packing']))
          productoFromApi(p, pedidoId: pedidoId, paquete: base),
      ],
    );
  }
}

/// Respuesta de `send_transfer/pack` / `send_cluster/pack`.
class PaqueteCreadoApi {
  final PaquetePacking paquete;

  /// Moves que quedaron dentro de la caja. Al dividir, Odoo les da un id_move
  /// nuevo; la parte que quedó en "por hacer" conserva el original.
  final List<ProductoPacking> filasEmpacadas;

  const PaqueteCreadoApi({required this.paquete, required this.filasEmpacadas});
}

/// Respuesta de `transferencias/unpacking` y `transferencias/delete_pack`.
///
/// Cada move trae en `quantity` el total que queda POR HACER de ese move
/// (incluye lo que el operario tenga separado sin empacar en el dispositivo).
class MovesDevueltosApi {
  final String mensaje;
  final List<Map<String, dynamic>> moves;

  /// El backend eliminó el paquete (desempaque del último producto).
  final bool paqueteEliminado;

  const MovesDevueltosApi({
    required this.mensaje,
    required this.moves,
    this.paqueteEliminado = false,
  });

  /// Move devuelto para la línea empacada: por producto + lote + ubicación,
  /// nunca por id_move (al dividir, Odoo cambia el id del move empacado).
  Map<String, dynamic>? moveDe(ProductoPacking empacada) {
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;

    final mismoProducto = moves
        .where((m) => OdooParse.integer(m['id_product']) == empacada.idProduct)
        .toList();
    if (mismoProducto.length == 1) return mismoProducto.first;
    if (mismoProducto.isEmpty) return null;

    for (final m in mismoProducto) {
      final lote = OdooParse.integer(m['lote_id']) ?? 0;
      final ubicacion = OdooParse.str(m['barcode_location']);
      if (lote == (empacada.loteId ?? 0) &&
          (ubicacion.isEmpty || ubicacion == empacada.barcodeLocation)) {
        return m;
      }
    }
    return mismoProducto.first;
  }
}
