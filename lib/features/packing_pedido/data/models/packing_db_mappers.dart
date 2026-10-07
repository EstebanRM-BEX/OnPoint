import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';

/// Conversión entidades ↔ filas de `packing_pedido_v2.db`.
class PackingDbMappers {
  const PackingDbMappers._();

  static int _b(bool v) => v ? 1 : 0;
  static bool _bool(Object? v) => v == 1 || v == true;
  static String _s(Object? v) => v == null ? '' : '$v';
  static double _d(Object? v) => v is num ? v.toDouble() : 0;
  static int? _i(Object? v) => v is num ? v.toInt() : null;

  // ── Pedido ────────────────────────────────────────────────────────────────

  static Map<String, Object?> pedidoToRow(PedidoPack p) => {
    'id': p.id,
    'batch_id': p.batchId,
    'name': p.name,
    'referencia': p.referencia,
    'contacto_name': p.contactoName,
    'observacion': p.observacion,
    'fecha_creacion': p.fechaCreacion?.toIso8601String(),
    'config_packing': p.configPacking,
    'priority': p.priority,
    'state': p.state,
    'picking_type': p.pickingType,
    'location_id': p.locationId,
    'location_name': p.locationName,
    'location_barcode': p.locationBarcode,
    'location_dest_id': p.locationDestId,
    'location_dest_name': p.locationDestName,
    'location_dest_barcode': p.locationDestBarcode,
    'warehouse_id': p.warehouseId,
    'warehouse_name': p.warehouseName,
    'location_name_cluster': p.locationNameCluster,
    'location_barcode_cluster': p.locationBarcodeCluster,
    'proveedor': p.proveedor,
    'propietario': p.propietario,
    'manejo_propietario': _b(p.manejoPropietario),
    'cantidad_productos': p.cantidadProductos,
    'responsable_id': p.responsableId,
    'responsable': p.responsable,
    'backorder_id': p.backorderId,
    'backorder_name': p.backorderName,
    'create_backorder': p.createBackorder,
    'numero_lineas': p.numeroLineas,
    'numero_items': p.numeroItems,
    'numero_paquetes': p.numeroPaquetes,
    'order_tms': p.orderTms,
    'zona_entrega': p.zonaEntrega,
    'zona_entrega_tms': p.zonaEntregaTms,
    'start_time_transfer': p.startTimeTransfer,
    'end_time_transfer': p.endTimeTransfer,
    'is_selected': _b(p.isSelected),
    'is_started': _b(p.isStarted),
    'is_terminate': _b(p.isTerminate),
  };

  static PedidoPack pedidoFromRow(Map<String, Object?> r) => PedidoPack(
    id: r['id'] as int,
    batchId: _i(r['batch_id']),
    name: _s(r['name']),
    referencia: _s(r['referencia']),
    contactoName: _s(r['contacto_name']),
    observacion: _s(r['observacion']),
    fechaCreacion: DateTime.tryParse(_s(r['fecha_creacion'])),
    configPacking: _s(r['config_packing']),
    priority: _s(r['priority']).isEmpty ? '0' : _s(r['priority']),
    state: _s(r['state']),
    pickingType: _s(r['picking_type']),
    locationId: _i(r['location_id']),
    locationName: _s(r['location_name']),
    locationBarcode: _s(r['location_barcode']),
    locationDestId: _i(r['location_dest_id']),
    locationDestName: _s(r['location_dest_name']),
    locationDestBarcode: _s(r['location_dest_barcode']),
    warehouseId: _i(r['warehouse_id']),
    warehouseName: _s(r['warehouse_name']),
    locationNameCluster: _s(r['location_name_cluster']),
    locationBarcodeCluster: _s(r['location_barcode_cluster']),
    proveedor: _s(r['proveedor']),
    propietario: _s(r['propietario']),
    manejoPropietario: _bool(r['manejo_propietario']),
    cantidadProductos: _i(r['cantidad_productos']) ?? 0,
    responsableId: _i(r['responsable_id']),
    responsable: _s(r['responsable']),
    backorderId: _i(r['backorder_id']),
    backorderName: _s(r['backorder_name']),
    createBackorder: _s(r['create_backorder']),
    numeroLineas: _i(r['numero_lineas']) ?? 0,
    numeroItems: _d(r['numero_items']),
    numeroPaquetes: _i(r['numero_paquetes']) ?? 0,
    orderTms: _s(r['order_tms']),
    zonaEntrega: _s(r['zona_entrega']),
    zonaEntregaTms: _s(r['zona_entrega_tms']),
    startTimeTransfer: _s(r['start_time_transfer']),
    endTimeTransfer: _s(r['end_time_transfer']),
    isSelected: _bool(r['is_selected']),
    isStarted: _bool(r['is_started']),
    isTerminate: _bool(r['is_terminate']),
  );

  // ── Producto ──────────────────────────────────────────────────────────────

  /// Campos que manda la API (se refrescan en cada sincronización sin tocar
  /// el avance del operario).
  static Map<String, Object?> productoDatosApi(ProductoPacking p) => {
    'pedido_id': p.pedidoId,
    'batch_id': p.batchId,
    'id_move': p.idMove,
    'id_product': p.idProduct,
    'product_name': p.productName,
    'product_code': p.productCode,
    'barcode': p.barcode,
    'lote_id': p.loteId,
    'lote_name': p.loteName,
    'expire_date': p.expireDate,
    'tracking': p.tracking,
    'unidades': p.unidades,
    'weight': p.weight,
    'id_location': p.idLocation,
    'location_name': p.locationName,
    'barcode_location': p.barcodeLocation,
    'id_location_dest': p.idLocationDest,
    'location_dest_name': p.locationDestName,
    'id_preparado': p.idPreparado,
    'maneja_temperatura': _b(p.manejaTemperatura),
  };

  /// Fila completa; sin `id` para que SQLite asigne la PK.
  static Map<String, Object?> productoToRow(ProductoPacking p) => {
    ...productoDatosApi(p),
    'quantity': p.quantity,
    'quantity_separate': p.quantitySeparate,
    'estado': p.estado.name,
    'certificado': _b(p.certificado),
    'is_product_split': _b(p.isProductSplit),
    'id_package': p.idPackage,
    'package_name': p.packageName,
    'observation': p.observation,
    'temperatura': p.temperatura,
    'image': p.image,
    'image_novedad': p.imageNovedad,
    'location_ok': _b(p.locationOk),
    'product_ok': _b(p.productOk),
    'quantity_ok': _b(p.quantityOk),
    'time_separate_start': p.timeSeparateStart?.toIso8601String(),
    'time_separate': p.timeSeparate,
  };

  static ProductoPacking productoFromRow(Map<String, Object?> r) {
    final estado = EstadoProductoPacking.values.firstWhere(
      (e) => e.name == r['estado'],
      orElse: () => EstadoProductoPacking.porHacer,
    );
    return ProductoPacking(
      id: r['id'] as int,
      pedidoId: r['pedido_id'] as int,
      batchId: _i(r['batch_id']),
      idMove: r['id_move'] as int,
      idProduct: r['id_product'] as int,
      productName: _s(r['product_name']),
      productCode: _s(r['product_code']),
      barcode: _s(r['barcode']),
      loteId: _i(r['lote_id']),
      loteName: _s(r['lote_name']),
      expireDate: _s(r['expire_date']),
      tracking: _s(r['tracking']),
      unidades: _s(r['unidades']),
      weight: _d(r['weight']),
      idLocation: _i(r['id_location']),
      locationName: _s(r['location_name']),
      barcodeLocation: _s(r['barcode_location']),
      idLocationDest: _i(r['id_location_dest']),
      locationDestName: _s(r['location_dest_name']),
      quantity: _d(r['quantity']),
      quantitySeparate: _d(r['quantity_separate']),
      estado: estado,
      certificado: _bool(r['certificado']),
      isProductSplit: _bool(r['is_product_split']),
      idPackage: _i(r['id_package']),
      packageName: _s(r['package_name']),
      idPreparado: _i(r['id_preparado']),
      observation: _s(r['observation']),
      manejaTemperatura: _bool(r['maneja_temperatura']),
      temperatura: _d(r['temperatura']),
      image: _s(r['image']),
      imageNovedad: _s(r['image_novedad']),
      locationOk: _bool(r['location_ok']),
      productOk: _bool(r['product_ok']),
      quantityOk: _bool(r['quantity_ok']),
      timeSeparateStart: DateTime.tryParse(_s(r['time_separate_start'])),
      timeSeparate: _d(r['time_separate']),
    );
  }

  // ── Paquete ───────────────────────────────────────────────────────────────

  static Map<String, Object?> paqueteToRow(PaquetePacking p) => {
    'id': p.id,
    'pedido_id': p.pedidoId,
    'batch_id': p.batchId,
    'name': p.name,
    'packing_barcode': p.packingBarcode,
    'consecutivo': p.consecutivo,
    'cantidad_productos': p.cantidadProductos,
    'is_sticker': _b(p.isSticker),
    'is_certificate': _b(p.isCertificate),
    'type_paquete': p.typePaquete,
    'peso': p.peso,
    'location_dest_id': p.locationDestId,
    'location_dest_name': p.locationDestName,
    'location_dest_barcode': p.locationDestBarcode,
  };

  static PaquetePacking paqueteFromRow(
    Map<String, Object?> r, {
    List<ProductoPacking> productos = const [],
  }) => PaquetePacking(
    id: r['id'] as int,
    pedidoId: r['pedido_id'] as int,
    batchId: _i(r['batch_id']),
    name: _s(r['name']),
    packingBarcode: _s(r['packing_barcode']),
    consecutivo: _s(r['consecutivo']),
    cantidadProductos: _i(r['cantidad_productos']) ?? productos.length,
    isSticker: _bool(r['is_sticker']),
    isCertificate: _bool(r['is_certificate']),
    typePaquete: _s(r['type_paquete']),
    peso: _d(r['peso']),
    locationDestId: _i(r['location_dest_id']),
    locationDestName: _s(r['location_dest_name']),
    locationDestBarcode: _s(r['location_dest_barcode']),
    productos: productos,
  );

  // ── Barcode ───────────────────────────────────────────────────────────────

  static Map<String, Object?> barcodeToRow(
    int pedidoId,
    BarcodeProductoPacking b,
  ) => {
    'pedido_id': pedidoId,
    'id_move': b.idMove,
    'id_product': b.idProduct,
    'barcode': b.barcode,
    'cantidad': b.cantidad,
  };

  static BarcodeProductoPacking barcodeFromRow(Map<String, Object?> r) =>
      BarcodeProductoPacking(
        idMove: _i(r['id_move']) ?? 0,
        idProduct: r['id_product'] as int,
        barcode: _s(r['barcode']),
        cantidad: _d(r['cantidad']) > 0 ? _d(r['cantidad']) : 1,
      );
}
