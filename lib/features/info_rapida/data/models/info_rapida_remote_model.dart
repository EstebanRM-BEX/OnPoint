import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/info_rapida/data/exceptions/info_rapida_exceptions.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/packing_pedido/data/models/odoo_parse.dart';

/// Decodificador y mapeador de respuestas JSON remotas para Información Rápida.
class InfoRapidaRemoteModel {
  const InfoRapidaRemoteModel._();

  /// Parsea la respuesta completa del backend (JSON-RPC o mapa `result`).
  ///
  /// Lanza excepciones tipadas si el backend devuelve un código de error:
  /// - [DispositivoNoAutorizadoException] si el código es 403.
  /// - [NoEncontradoException] si el código es 404.
  /// - [ActualizarVersionException] si `update_version` es true.
  /// - [SessionExpiredException] si el código de error es 100.
  /// - [ServerException] si el código es 400, 500 o desconocido.
  static InfoRapida fromJsonRpc(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      final error = json['error'];
      if (error is Map) {
        final code = OdooParse.integer(error['code']);
        final msg = OdooParse.str(error['message'] ?? error['msg']);
        if (code == 100) {
          throw const SessionExpiredException(
            'Sesión expirada, por favor inicie sesión nuevamente',
          );
        }
        throw ServerException(msg.isEmpty ? 'Error del servidor' : msg);
      }
    }

    final rawResult = json['result'];
    if (rawResult is! Map<String, dynamic>) {
      throw const ServerException('Respuesta sin contenido del servidor');
    }

    return fromResultMap(rawResult);
  }

  /// Parsea directamente el mapa `result` interno de la respuesta.
  static InfoRapida fromResultMap(Map<String, dynamic> resultMap) {
    final code = OdooParse.integer(resultMap['code']) ?? 200;
    final msg = OdooParse.str(resultMap['msg']);
    final updateVersion = OdooParse.boolean(resultMap['update_version']);

    if (updateVersion) {
      throw ActualizarVersionException(
        msg.isEmpty
            ? 'Hay una actualización requerida para continuar utilizando la app.'
            : msg,
      );
    }

    if (code == 403) {
      throw DispositivoNoAutorizadoException(
        msg.isEmpty
            ? 'Este dispositivo no está autorizado para usar la aplicación.'
            : msg,
      );
    }

    if (code == 404) {
      throw NoEncontradoException(
        msg.isEmpty
            ? 'El producto, ubicación o paquete consultado no fue encontrado.'
            : msg,
      );
    }

    if (code != 200) {
      throw ServerException(msg.isEmpty ? 'Error en la consulta ($code)' : msg);
    }

    final type = OdooParse.str(resultMap['type']).toLowerCase();
    final innerResult = resultMap['result'];

    if (innerResult is! Map<String, dynamic>) {
      throw const NoEncontradoException('La consulta no devolvió datos válidos.');
    }

    switch (type) {
      case 'product':
        return _parseProducto(innerResult);
      case 'ubicacion':
        return _parseUbicacion(innerResult);
      case 'paquete':
        return _parsePaquete(innerResult);
      default:
        // Si el type no está explícito, inferimos por sus propiedades:
        if (innerResult.containsKey('ubicaciones')) {
          return _parseProducto(innerResult);
        } else if (innerResult.containsKey('productos')) {
          if (innerResult.containsKey('is_certificate') ||
              innerResult.containsKey('fecha_empaquetado')) {
            return _parsePaquete(innerResult);
          }
          return _parseUbicacion(innerResult);
        }
        throw ServerException('Tipo de resultado desconocido: $type');
    }
  }

  static ProductoInfo _parseProducto(Map<String, dynamic> map) {
    final ubicacionesRaw = map['ubicaciones'];
    final ubicaciones = <UbicacionProducto>[];

    if (ubicacionesRaw is List) {
      for (final u in ubicacionesRaw) {
        if (u is Map) {
          final uMap = Map<String, dynamic>.from(u);
          ubicaciones.add(
            UbicacionProducto(
              idMove: OdooParse.integer(uMap['id_move']),
              idAlmacen: OdooParse.integer(uMap['id_almacen']),
              idUbicacion: OdooParse.integer(uMap['id_ubicacion']) ?? 0,
              ubicacion: OdooParse.str(uMap['ubicacion']),
              cantidad: OdooParse.dbl(uMap['cantidad']),
              reservado: OdooParse.dbl(uMap['reservado']),
              cantidadMano: OdooParse.dbl(uMap['cantidad_mano']),
              codigoBarras: OdooParse.str(uMap['codigo_barras']),
              lote: OdooParse.str(uMap['lote']).isEmpty
                  ? null
                  : OdooParse.str(uMap['lote']),
              loteId: OdooParse.integer(uMap['lote_id']),
              fechaEliminacion: OdooParse.str(uMap['fecha_eliminacion']).isEmpty
                  ? null
                  : OdooParse.str(uMap['fecha_eliminacion']),
              fechaCaducidad: OdooParse.str(uMap['fecha_caducidad']).isEmpty
                  ? null
                  : OdooParse.str(uMap['fecha_caducidad']),
              fechaEntrada: OdooParse.str(uMap['fecha_entrada']).isEmpty
                  ? null
                  : OdooParse.str(uMap['fecha_entrada']),
              unidadMedida: OdooParse.str(uMap['unidad_medida']).isEmpty
                  ? null
                  : OdooParse.str(uMap['unidad_medida']),
              packing: uMap['packing'] != null
                  ? OdooParse.boolean(uMap['packing'])
                  : null,
              nombrePaquete: OdooParse.str(uMap['nombre_paquete']).isEmpty
                  ? null
                  : OdooParse.str(uMap['nombre_paquete']),
              propietario: OdooParse.str(uMap['propietario']).isEmpty
                  ? null
                  : OdooParse.str(uMap['propietario']),
              idPropietario: OdooParse.integer(uMap['id_propietario']),
              manejoPropietario: uMap['manejo_propietario'] != null
                  ? OdooParse.boolean(uMap['manejo_propietario'])
                  : null,
            ),
          );
        }
      }
    }

    final categoria = OdooParse.str(map['categoria']);
    final unidadMedida = OdooParse.str(map['unidad_medida']);
    final fechaEmpaquetado = OdooParse.str(map['fecha_empaquetado']);
    final propietario = OdooParse.str(map['propietario']);

    return ProductoInfo(
      id: OdooParse.integer(map['id']) ?? 0,
      nombre: OdooParse.str(map['nombre']),
      precio: map['precio'] != null ? OdooParse.dbl(map['precio']) : null,
      referencia: OdooParse.str(map['referencia']),
      peso: map['peso'] != null ? OdooParse.dbl(map['peso']) : null,
      volumen: map['volumen'] != null ? OdooParse.dbl(map['volumen']) : null,
      codigoBarras: OdooParse.str(map['codigo_barras']),
      cantidadDisponible: map['cantidad_disponible'] != null
          ? OdooParse.dbl(map['cantidad_disponible'])
          : null,
      previsto: map['previsto'] != null ? OdooParse.dbl(map['previsto']) : null,
      categoria: categoria.isEmpty ? null : categoria,
      unidadMedida: unidadMedida.isEmpty ? null : unidadMedida,
      isSticker: map['is_sticker'] != null
          ? OdooParse.boolean(map['is_sticker'])
          : null,
      isCertificate: map['is_certificate'] != null
          ? OdooParse.boolean(map['is_certificate'])
          : null,
      fechaEmpaquetado: fechaEmpaquetado.isEmpty ? null : fechaEmpaquetado,
      ubicaciones: List.unmodifiable(ubicaciones),
      idPropietario: OdooParse.integer(map['id_propietario']),
      propietario: propietario.isEmpty ? null : propietario,
      manejoPropietario: map['manejo_propietario'] != null
          ? OdooParse.boolean(map['manejo_propietario'])
          : null,
    );
  }

  static UbicacionInfo _parseUbicacion(Map<String, dynamic> map) {
    final productosRaw = map['productos'];
    final productos = <ProductoUbicacion>[];

    if (productosRaw is List) {
      for (final p in productosRaw) {
        if (p is Map) {
          productos.add(_parseProductoUbicacion(Map<String, dynamic>.from(p)));
        }
      }
    }

    final ubicacionPadre = OdooParse.str(map['ubicacion_padre']);
    final tipoUbicacion = OdooParse.str(map['tipo_ubicacion']);
    final nombreAlmacen = OdooParse.str(map['nombre_almacen']);
    final nombreCompleto = OdooParse.str(map['nombre_completo']);
    final propietario = OdooParse.str(map['propietario']);

    return UbicacionInfo(
      id: OdooParse.integer(map['id']) ?? 0,
      nombre: OdooParse.str(map['nombre']),
      codigoBarras: OdooParse.str(map['codigo_barras']),
      ubicacionPadre: ubicacionPadre.isEmpty ? null : ubicacionPadre,
      tipoUbicacion: tipoUbicacion.isEmpty ? null : tipoUbicacion,
      nombreAlmacen: nombreAlmacen.isEmpty ? null : nombreAlmacen,
      nombreCompleto: nombreCompleto.isEmpty ? null : nombreCompleto,
      numeroPedidos: OdooParse.integer(map['numero_pedidos']),
      totalProductos: map['total_productos'] != null
          ? OdooParse.dbl(map['total_productos'])
          : null,
      numeroProductos: OdooParse.integer(map['numero_productos']),
      productos: List.unmodifiable(productos),
      idPropietario: OdooParse.integer(map['id_propietario']),
      propietario: propietario.isEmpty ? null : propietario,
      manejoPropietario: map['manejo_propietario'] != null
          ? OdooParse.boolean(map['manejo_propietario'])
          : null,
    );
  }

  static PaqueteInfo _parsePaquete(Map<String, dynamic> map) {
    final productosRaw = map['productos'];
    final productos = <ProductoUbicacion>[];

    if (productosRaw is List) {
      for (final p in productosRaw) {
        if (p is Map) {
          productos.add(_parseProductoUbicacion(Map<String, dynamic>.from(p)));
        }
      }
    }

    final nombreAlmacen = OdooParse.str(map['nombre_almacen']);
    final fechaEmpaquetado = OdooParse.str(map['fecha_empaquetado']);

    return PaqueteInfo(
      id: OdooParse.integer(map['id']),
      nombre: OdooParse.str(map['nombre']),
      codigoBarras: OdooParse.str(map['codigo_barras']),
      totalProductos: map['total_productos'] != null
          ? OdooParse.dbl(map['total_productos'])
          : null,
      numeroProductos: OdooParse.integer(map['numero_productos']),
      isCertificate: map['is_certificate'] != null
          ? OdooParse.boolean(map['is_certificate'])
          : null,
      nombreAlmacen: nombreAlmacen.isEmpty ? null : nombreAlmacen,
      fechaEmpaquetado: fechaEmpaquetado.isEmpty ? null : fechaEmpaquetado,
      productos: List.unmodifiable(productos),
    );
  }

  static ProductoUbicacion _parseProductoUbicacion(Map<String, dynamic> pMap) {
    final lote = OdooParse.str(pMap['lote']);
    final unidadMedida = OdooParse.str(pMap['unidad_medida']);
    final pedido = OdooParse.str(pMap['pedido']);
    final origin = OdooParse.str(pMap['origin']);
    final tercero = OdooParse.str(pMap['tercero']);
    final numeroCaja = OdooParse.str(pMap['numero_caja']);
    final nombreAlmacen = OdooParse.str(pMap['nombre_almacen']);
    final operador = OdooParse.str(pMap['operador']);
    final fechaVencimiento = OdooParse.str(pMap['fecha_vencimiento']);
    final nombrePaquete = OdooParse.str(pMap['nombre_paquete']);
    final propietario = OdooParse.str(pMap['propietario']);

    return ProductoUbicacion(
      id: OdooParse.integer(pMap['id']) ?? 0,
      producto: OdooParse.str(pMap['producto']),
      cantidad: OdooParse.dbl(pMap['cantidad']),
      reservado: OdooParse.dbl(pMap['reservado']),
      cantidadMano: OdooParse.dbl(pMap['cantidad_mano']),
      codigoBarras: OdooParse.str(pMap['codigo_barras']),
      loteId: OdooParse.integer(pMap['lote_id']),
      lote: lote.isEmpty ? null : lote,
      unidadMedida: unidadMedida.isEmpty ? null : unidadMedida,
      pedido: pedido.isEmpty ? null : pedido,
      origin: origin.isEmpty ? null : origin,
      tercero: tercero.isEmpty ? null : tercero,
      numeroCaja: numeroCaja.isEmpty ? null : numeroCaja,
      nombreAlmacen: nombreAlmacen.isEmpty ? null : nombreAlmacen,
      operador: operador.isEmpty ? null : operador,
      fechaVencimiento: fechaVencimiento.isEmpty ? null : fechaVencimiento,
      packing: pMap['packing'] != null
          ? OdooParse.boolean(pMap['packing'])
          : null,
      nombrePaquete: nombrePaquete.isEmpty ? null : nombrePaquete,
      propietario: propietario.isEmpty ? null : propietario,
      idPropietario: OdooParse.integer(pMap['id_propietario']),
      manejoPropietario: pMap['manejo_propietario'] != null
          ? OdooParse.boolean(pMap['manejo_propietario'])
          : null,
    );
  }
}
