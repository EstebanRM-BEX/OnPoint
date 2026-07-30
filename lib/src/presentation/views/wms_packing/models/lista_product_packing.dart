import 'dart:convert';

import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';

class ProductoPedido {
  final int? id;
  final dynamic productId;
  final int? batchId;
  final int? pedidoId;
  final int? idMove;
  final dynamic idProduct;
  final dynamic loteId;
  final dynamic lotId;
  final dynamic locationId;
  final dynamic idLocation;
  final dynamic locationDestId;
  final dynamic idLocationDest;
  final dynamic quantity;
  final int? pendingQuantity;
  final String? tracking;
  final dynamic barcode;
  final dynamic weight;
  final String? unidades;
  final String? observation;
  final int? isPacking;
  final int? idPackage;
  final dynamic packageName;
  final dynamic productCode;
  final int? isPackage;
  final dynamic isCertificate;
  final int? isSendOdoo;
  final dynamic isProductSplit;
  final String? isSendOdooDate;
  final dynamic expireDate;

  //vairbales para el packing
  final List<Barcodes>? productPacking;
  final List<Barcodes>? otherBarcode;

  final dynamic barcodeLocation;
  final dynamic quantitySeparate;
  final dynamic isSelected;
  final dynamic isSeparate;
  final dynamic
      isLocationIsOk; // Variable para si la ubicación es leída correctamente
  final dynamic
      productIsOk; // Variable para si el producto es leído correctamente
  final dynamic
      locationDestIsOk; // Variable para si la ubicación destino está leída
  final dynamic isQuantityIsOk; // V
  final String? type;

  final dynamic manejaTemperatura;
  final dynamic temperatura;
  final dynamic image;
  final dynamic imageNovedad;

  final dynamic timeSeparate;
  final dynamic timeSeparatStart;
  final dynamic timeSeparateEnd;
  // cantidad_total_pedidos":
  final dynamic cantidadTotalPedidos;

  // "cantidad_total_productos":
  final dynamic cantidadTotalProductos;

  ProductoPedido(
      {this.id,
      this.productId,
      this.batchId,
      this.pedidoId,
      this.idProduct,
      this.loteId,
      this.productCode,
      this.idMove,
      this.lotId,
      this.locationId,
      this.idLocation,
      this.locationDestId,
      this.idLocationDest,
      this.quantity,
      this.pendingQuantity,
      this.tracking,
      this.barcode,
      this.weight,
      this.unidades,
      this.quantitySeparate,
      this.isSelected,
      this.isSeparate,
      this.isPacking,
      this.isLocationIsOk,
      this.productIsOk,
      this.locationDestIsOk,
      this.isQuantityIsOk,
      this.observation,
      this.idPackage,
      this.packageName,
      this.isPackage,
      this.isCertificate,
      this.isSendOdoo,
      this.isProductSplit,
      this.isSendOdooDate,
      this.productPacking,
      this.otherBarcode,
      this.barcodeLocation,
      this.expireDate,
      this.type,
      this.manejaTemperatura,
      this.temperatura,
      this.image,
      this.imageNovedad,
      this.timeSeparate,
      this.timeSeparatStart,
      this.cantidadTotalPedidos,
      this.cantidadTotalProductos,
      this.timeSeparateEnd});

  factory ProductoPedido.fromJson(String str) =>
      ProductoPedido.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ProductoPedido.fromMap(Map<String, dynamic> json) => ProductoPedido(
      id: json["id"],
      productId: json["product_id"],
      batchId: json["batch_id"],
      pedidoId: json["pedido_id"],
      idProduct: json["id_product"],
      productCode: json["product_code"],
      loteId: json["lote_id"],
      idMove: json["id_move"],
      lotId: json["lot_id"],
      locationId: json["location_id"],
      idLocation: json["id_location"],
      locationDestId: json["location_dest_id"],
      idLocationDest: json["id_location_dest"],
      quantity: json["quantity"],
      pendingQuantity: json["pending_quantity"],
      tracking: json["tracking"],
      barcode: json["barcode"],
      weight: json["weight"],
      unidades: json["unidades"],
      quantitySeparate: json["quantity_separate"],
      isSelected: json["is_selected"],
      isSeparate: json["is_separate"],
      isLocationIsOk: json["is_location_is_ok"] ?? false,
      productIsOk: json["product_is_ok"] ?? false,
      locationDestIsOk: json["location_dest_is_ok"] ?? false,
      isQuantityIsOk: json["is_quantity_is_ok"] ?? false,
      observation: json["observation"],
      expireDate: json["expire_date"],
      idPackage: json["id_package"],
      packageName: json["package_name"],
      isPackage: json["is_package"],
      isCertificate: json["is_certificate"],
      isSendOdoo: json["is_send_odoo"],
      isProductSplit: json["is_product_split"],
      isSendOdooDate: json["is_send_odoo_date"],
      productPacking: json['product_packing'] == null
          ? []
          : List<Barcodes>.from(
              json['product_packing'].map((x) => Barcodes.fromMap(x))),
      otherBarcode: json['other_barcode'] == null
          ? []
          : List<Barcodes>.from(
              json['other_barcode'].map((x) => Barcodes.fromMap(x))),
      barcodeLocation: json["barcode_location"],
      type: json["type"],
      manejaTemperatura: json["maneja_temperatura"],
      temperatura: json["temperatura"],
      image: json["image"],
      imageNovedad: json["image_novedad"],
      timeSeparate: json["time_separate"],
      timeSeparatStart: json['time_separate_start'],
      cantidadTotalPedidos: json['cantidad_total_pedidos'],
      cantidadTotalProductos: json['cantidad_total_productos'],
      timeSeparateEnd: json["time_separate_end"]);

  Map<String, dynamic> toMap() => {
        "id": id,
        "product_id": productId,
        "batch_id": batchId,
        "pedido_id": pedidoId,
        "id_product": idProduct,
        "lote_id": loteId,
        "lot_id": lotId,
        "product_code": productCode,
        "id_move": idMove,
        "location_id": locationId,
        "id_location": idLocation,
        "location_dest_id": locationDestId,
        "id_location_dest": idLocationDest,
        "quantity": quantity,
        "pending_quantity": pendingQuantity,
        "tracking": tracking,
        "barcode": barcode,
        "weight": weight,
        "unidades": unidades,
        "quantity_separate": quantitySeparate,
        "is_selected": isSelected,
        "is_separate": isSeparate,
        "is_location_is_ok": isLocationIsOk,
        "product_is_ok": productIsOk,
        "location_dest_is_ok": locationDestIsOk,
        "is_quantity_is_ok": isQuantityIsOk,
        "observation": observation,
        "id_package": idPackage,
        "package_name": packageName,
        "is_package": isPackage,
        "is_certificate": isCertificate,
        "is_product_split": isProductSplit,
        "is_send_odoo": isSendOdoo,
        "expire_date": expireDate,
        "is_send_odoo_date": isSendOdooDate,
        "product_packing": productPacking == null
            ? []
            : List<dynamic>.from(productPacking!.map((x) => x.toMap())),
        "other_barcode": otherBarcode == null
            ? []
            : List<dynamic>.from(otherBarcode!.map((x) => x.toMap())),
        "barcode_location": barcodeLocation,
        "type": type,
        "maneja_temperatura": manejaTemperatura,
        "temperatura": temperatura,
        "image": image,
        "image_novedad": imageNovedad,
        "time_separate": timeSeparate,
        "time_separate_start": timeSeparatStart,
        "cantidad_total_pedidos": cantidadTotalPedidos,
        "cantidad_total_productos": cantidadTotalProductos,
        "time_separate_end": timeSeparateEnd,
      };

  // Cada línea de pedido/movimiento se identifica de forma única por
  // idMove (viene de Odoo). Sin esta igualdad por valor, List.contains()/
  // remove() comparan por identidad de instancia: cuando la pantalla
  // recarga listOfProductosProgress con nuevas instancias tras cada scan,
  // el checkbox deja de reconocer productos ya seleccionados y las
  // instancias viejas quedan huérfanas en listOfProductsForPacking,
  // duplicando el conteo de unidades al des/re-seleccionar.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductoPedido &&
          runtimeType == other.runtimeType &&
          idMove == other.idMove;

  @override
  int get hashCode => idMove.hashCode;
}
