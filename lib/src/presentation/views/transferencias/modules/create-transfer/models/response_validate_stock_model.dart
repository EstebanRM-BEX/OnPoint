import 'dart:convert';

class RespondeValidateStock {
    final String? jsonrpc;
    final dynamic id;
    final ResultValidateStock? result;

    RespondeValidateStock({
        this.jsonrpc,
        this.id,
        this.result,
    });

    factory RespondeValidateStock.fromJson(String str) => RespondeValidateStock.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory RespondeValidateStock.fromMap(Map<String, dynamic> json) => RespondeValidateStock(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : ResultValidateStock.fromMap(json["result"]),
    );

    Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toMap(),
    };
}

class ResultValidateStock {
    final int? code;
    final String? msg;
    final Consulta? consulta;
    final ResumenStock? resumenStock;
    final List<dynamic>? correccionesRealizadas;
    final List<DetalleQuantsEncontrado>? detalleQuantsEncontrados;

    ResultValidateStock({
        this.code,
        this.msg,
        this.consulta,
        this.resumenStock,
        this.correccionesRealizadas,
        this.detalleQuantsEncontrados,
    });

    factory ResultValidateStock.fromJson(String str) => ResultValidateStock.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResultValidateStock.fromMap(Map<String, dynamic> json) => ResultValidateStock(
        code: json["code"],
        msg: json["msg"],
        consulta: json["consulta"] == null ? null : Consulta.fromMap(json["consulta"]),
        resumenStock: json["resumen_stock"] == null ? null : ResumenStock.fromMap(json["resumen_stock"]),
        correccionesRealizadas: json["correcciones_realizadas"] == null ? [] : List<dynamic>.from(json["correcciones_realizadas"]!.map((x) => x)),
        detalleQuantsEncontrados: json["detalle_quants_encontrados"] == null ? [] : List<DetalleQuantsEncontrado>.from(json["detalle_quants_encontrados"]!.map((x) => DetalleQuantsEncontrado.fromMap(x))),
    );

    Map<String, dynamic> toMap() => {
        "code": code,
        "msg": msg,
        "consulta": consulta?.toMap(),
        "resumen_stock": resumenStock?.toMap(),
        "correcciones_realizadas": correccionesRealizadas == null ? [] : List<dynamic>.from(correccionesRealizadas!.map((x) => x)),
        "detalle_quants_encontrados": detalleQuantsEncontrados == null ? [] : List<dynamic>.from(detalleQuantsEncontrados!.map((x) => x.toMap())),
    };
}

class Consulta {
    final int? productoId;
    final String? productoNombre;
    final String? productoCodigo;
    final int? ubicacionId;
    final String? ubicacionNombreCompleto;
    final String? ubicacionBarcode;
    final int? loteId;
    final String? loteNombre;
    final dynamic cantidadConsultada;

    Consulta({
        this.productoId,
        this.productoNombre,
        this.productoCodigo,
        this.ubicacionId,
        this.ubicacionNombreCompleto,
        this.ubicacionBarcode,
        this.loteId,
        this.loteNombre,
        this.cantidadConsultada,
    });

    factory Consulta.fromJson(String str) => Consulta.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory Consulta.fromMap(Map<String, dynamic> json) => Consulta(
        productoId: json["producto_id"],
        productoNombre: json["producto_nombre"],
        productoCodigo: json["producto_codigo"],
        ubicacionId: json["ubicacion_id"],
        ubicacionNombreCompleto: json["ubicacion_nombre_completo"],
        ubicacionBarcode: json["ubicacion_barcode"],
        loteId: json["lote_id"],
        loteNombre: json["lote_nombre"],
        cantidadConsultada: json["cantidad_consultada"],
    );

    Map<String, dynamic> toMap() => {
        "producto_id": productoId,
        "producto_nombre": productoNombre,
        "producto_codigo": productoCodigo,
        "ubicacion_id": ubicacionId,
        "ubicacion_nombre_completo": ubicacionNombreCompleto,
        "ubicacion_barcode": ubicacionBarcode,
        "lote_id": loteId,
        "lote_nombre": loteNombre,
        "cantidad_consultada": cantidadConsultada,
    };
}

class DetalleQuantsEncontrado {
    final int? quantId;
    final int? lotId;
    final String? lotName;
    final dynamic cantidadAMano;
    final dynamic cantidadReservada;
    final dynamic disponibleEnEsteQuant;
    final int? packageId;
    final String? packageName;

    DetalleQuantsEncontrado({
        this.quantId,
        this.lotId,
        this.lotName,
        this.cantidadAMano,
        this.cantidadReservada,
        this.disponibleEnEsteQuant,
        this.packageId,
        this.packageName,
    });

    factory DetalleQuantsEncontrado.fromJson(String str) => DetalleQuantsEncontrado.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory DetalleQuantsEncontrado.fromMap(Map<String, dynamic> json) => DetalleQuantsEncontrado(
        quantId: json["quant_id"],
        lotId: json["lot_id"],
        lotName: json["lot_name"],
        cantidadAMano: json["cantidad_a_mano"],
        cantidadReservada: json["cantidad_reservada"],
        disponibleEnEsteQuant: json["disponible_en_este_quant"],
        packageId: json["package_id"],
        packageName: json["package_name"],
    );

    Map<String, dynamic> toMap() => {
        "quant_id": quantId,
        "lot_id": lotId,
        "lot_name": lotName,
        "cantidad_a_mano": cantidadAMano,
        "cantidad_reservada": cantidadReservada,
        "disponible_en_este_quant": disponibleEnEsteQuant,
        "package_id": packageId,
        "package_name": packageName,
    };
}

class ResumenStock {
    final dynamic stockTotalALaMano;
    final dynamic stockReservadoTotal;
    final dynamic stockDisponibleCalculado;
    final bool? esSuficiente;

    ResumenStock({
        this.stockTotalALaMano,
        this.stockReservadoTotal,
        this.stockDisponibleCalculado,
        this.esSuficiente,
    });

    factory ResumenStock.fromJson(String str) => ResumenStock.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory ResumenStock.fromMap(Map<String, dynamic> json) => ResumenStock(
        stockTotalALaMano: json["stock_total_a_la_mano"],
        stockReservadoTotal: json["stock_reservado_total"],
        stockDisponibleCalculado: json["stock_disponible_calculado"],
        esSuficiente: json["es_suficiente"],
    );

    Map<String, dynamic> toMap() => {
        "stock_total_a_la_mano": stockTotalALaMano,
        "stock_reservado_total": stockReservadoTotal,
        "stock_disponible_calculado": stockDisponibleCalculado,
        "es_suficiente": esSuficiente,
    };
}
