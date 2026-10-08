import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/core/error/exceptions.dart';
import 'package:wms_app/features/info_rapida/data/exceptions/info_rapida_exceptions.dart';
import 'package:wms_app/features/info_rapida/data/models/info_rapida_remote_model.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';

void main() {
  group('InfoRapidaRemoteModel - fromJsonRpc', () {
    test('lanza SessionExpiredException cuando error.code == 100', () {
      final json = {
        'error': {
          'code': 100,
          'message': 'Session expired',
        },
      };

      expect(
        () => InfoRapidaRemoteModel.fromJsonRpc(json),
        throwsA(isA<SessionExpiredException>()),
      );
    });

    test('lanza ServerException cuando error contiene otro código', () {
      final json = {
        'error': {
          'code': 500,
          'message': 'Internal database error',
        },
      };

      expect(
        () => InfoRapidaRemoteModel.fromJsonRpc(json),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Internal database error',
          ),
        ),
      );
    });

    test('lanza ServerException si result no es un Map', () {
      final json = {'result': 'invalid'};
      expect(
        () => InfoRapidaRemoteModel.fromJsonRpc(json),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('InfoRapidaRemoteModel - fromResultMap errores', () {
    test('update_version con resultado lo devuelve marcado (bug 6: solo avisar)',
        () {
      final info = InfoRapidaRemoteModel.fromResultMap({
        'code': 200,
        'update_version': true,
        'type': 'ubicacion',
        'result': {'id': 10, 'nombre': 'A1', 'productos': []},
      });

      expect(info, isA<UbicacionInfo>());
      expect(info.actualizarVersion, isTrue);
    });

    test('sin update_version el resultado no viene marcado', () {
      final info = InfoRapidaRemoteModel.fromResultMap({
        'code': 200,
        'type': 'ubicacion',
        'result': {'id': 10, 'nombre': 'A1', 'productos': []},
      });

      expect(info.actualizarVersion, isFalse);
    });

    test('update_version con 404 sigue siendo "no encontrado"', () {
      expect(
        () => InfoRapidaRemoteModel.fromResultMap({
          'code': 404,
          'update_version': true,
        }),
        throwsA(isA<NoEncontradoException>()),
      );
    });

    test('lanza ActualizarVersionException si update_version es true', () {
      final resultMap = {
        'code': 200,
        'update_version': true,
        'msg': 'Por favor actualice la app en la tienda',
      };

      expect(
        () => InfoRapidaRemoteModel.fromResultMap(resultMap),
        throwsA(
          isA<ActualizarVersionException>().having(
            (e) => e.message,
            'message',
            'Por favor actualice la app en la tienda',
          ),
        ),
      );
    });

    test('lanza DispositivoNoAutorizadoException si code == 403', () {
      final resultMap = {
        'code': 403,
        'msg': 'Dispositivo bloqueado',
      };

      expect(
        () => InfoRapidaRemoteModel.fromResultMap(resultMap),
        throwsA(
          isA<DispositivoNoAutorizadoException>().having(
            (e) => e.message,
            'message',
            'Dispositivo bloqueado',
          ),
        ),
      );
    });

    test('lanza NoEncontradoException si code == 404', () {
      final resultMap = {
        'code': 404,
        'msg': 'Código de barras no encontrado',
      };

      expect(
        () => InfoRapidaRemoteModel.fromResultMap(resultMap),
        throwsA(
          isA<NoEncontradoException>().having(
            (e) => e.message,
            'message',
            'Código de barras no encontrado',
          ),
        ),
      );
    });

    test('lanza ServerException si code != 200 genérico', () {
      final resultMap = {
        'code': 500,
        'msg': 'Error en el servidor Odoo',
      };

      expect(
        () => InfoRapidaRemoteModel.fromResultMap(resultMap),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Error en el servidor Odoo',
          ),
        ),
      );
    });

    test('lanza NoEncontradoException si el campo result interno no es un Map', () {
      final resultMap = {
        'code': 200,
        'result': false,
      };

      expect(
        () => InfoRapidaRemoteModel.fromResultMap(resultMap),
        throwsA(isA<NoEncontradoException>()),
      );
    });

    test('lanza ServerException si el tipo es desconocido y no se puede inferir', () {
      final resultMap = {
        'code': 200,
        'type': 'desconocido',
        'result': {'foo': 'bar'},
      };

      expect(
        () => InfoRapidaRemoteModel.fromResultMap(resultMap),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('InfoRapidaRemoteModel - parsing exitoso de entidades', () {
    test('parsea ProductoInfo con sus ubicaciones anidadas correctamente', () {
      final resultMap = {
        'code': 200,
        'type': 'product',
        'result': {
          'id': 101,
          'nombre': 'Martillo de Acero 16oz',
          'precio': 25000.5,
          'referencia': 'MAR-16OZ',
          'peso': 0.85,
          'volumen': 0.002,
          'codigo_barras': '7709998881112',
          'cantidad_disponible': 45.0,
          'previsto': 50.0,
          'categoria': 'Herramientas',
          'unidad_medida': 'Unidades',
          'is_sticker': true,
          'is_certificate': false,
          'fecha_empaquetado': '2026-09-01',
          'id_propietario': 5,
          'propietario': 'Ferretería Central',
          'manejo_propietario': true,
          'ubicaciones': [
            {
              'id_move': 1001,
              'id_almacen': 1,
              'id_ubicacion': 205,
              'ubicacion': 'WH/Stock/Pasillo 1',
              'cantidad': 25.0,
              'reservado': 5.0,
              'cantidad_mano': 30.0,
              'codigo_barras': 'LOC-P1',
              'lote': 'LOT-2026-A',
              'lote_id': 88,
              'fecha_eliminacion': '2027-01-01',
              'fecha_caducidad': '2027-06-01',
              'fecha_entrada': '2026-01-15',
              'unidad_medida': 'Unidades',
              'packing': false,
              'nombre_paquete': 'PACK-001',
              'id_propietario': 5,
              'propietario': 'Ferretería Central',
              'manejo_propietario': true,
            }
          ],
        },
      };

      final info = InfoRapidaRemoteModel.fromResultMap(resultMap);

      expect(info, isA<ProductoInfo>());
      final p = info as ProductoInfo;
      expect(p.id, 101);
      expect(p.nombre, 'Martillo de Acero 16oz');
      expect(p.precio, 25000.5);
      expect(p.referencia, 'MAR-16OZ');
      expect(p.peso, 0.85);
      expect(p.volumen, 0.002);
      expect(p.codigoBarras, '7709998881112');
      expect(p.cantidadDisponible, 45.0);
      expect(p.previsto, 50.0);
      expect(p.categoria, 'Herramientas');
      expect(p.unidadMedida, 'Unidades');
      expect(p.isSticker, true);
      expect(p.isCertificate, false);
      expect(p.idPropietario, 5);
      expect(p.propietario, 'Ferretería Central');
      expect(p.manejoPropietario, true);

      expect(p.ubicaciones.length, 1);
      final u = p.ubicaciones.first;
      expect(u.idMove, 1001);
      expect(u.idAlmacen, 1);
      expect(u.idUbicacion, 205);
      expect(u.ubicacion, 'WH/Stock/Pasillo 1');
      expect(u.cantidad, 25.0);
      expect(u.reservado, 5.0);
      expect(u.cantidadMano, 30.0);
      expect(u.codigoBarras, 'LOC-P1');
      expect(u.lote, 'LOT-2026-A');
      expect(u.loteId, 88);
      expect(u.fechaEliminacion, '2027-01-01');
      expect(u.fechaCaducidad, '2027-06-01');
      expect(u.fechaEntrada, '2026-01-15');
      expect(u.nombrePaquete, 'PACK-001');
      expect(u.propietario, 'Ferretería Central');
      expect(u.idPropietario, 5);
      expect(u.manejoPropietario, true);
    });

    test('parsea UbicacionInfo con productos contenidos', () {
      final resultMap = {
        'code': 200,
        'type': 'ubicacion',
        'result': {
          'id': 205,
          'nombre': 'Pasillo 1',
          'codigo_barras': 'LOC-P1',
          'ubicacion_padre': 'WH/Stock',
          'tipo_ubicacion': 'internal',
          'nombre_almacen': 'Almacén Principal',
          'nombre_completo': 'WH/Stock/Pasillo 1',
          'numero_pedidos': 12,
          'total_productos': 150.0,
          'numero_productos': 4,
          'id_propietario': 3,
          'propietario': 'Logística Integral',
          'manejo_propietario': true,
          'productos': [
            {
              'id': 101,
              'producto': 'Martillo',
              'codigo_barras': '7709998881112',
              'unidad_medida': 'Unidades',
              'cantidad': 25.0,
              'reservado': 5.0,
              'cantidad_mano': 30.0,
              'lote': 'LOT-1',
              'lote_id': 88,
              'id_propietario': 3,
              'propietario': 'Logística Integral',
              'manejo_propietario': true,
            }
          ],
        },
      };

      final info = InfoRapidaRemoteModel.fromResultMap(resultMap);

      expect(info, isA<UbicacionInfo>());
      final u = info as UbicacionInfo;
      expect(u.id, 205);
      expect(u.nombre, 'Pasillo 1');
      expect(u.codigoBarras, 'LOC-P1');
      expect(u.ubicacionPadre, 'WH/Stock');
      expect(u.tipoUbicacion, 'internal');
      expect(u.nombreAlmacen, 'Almacén Principal');
      expect(u.nombreCompleto, 'WH/Stock/Pasillo 1');
      expect(u.numeroPedidos, 12);
      expect(u.totalProductos, 150.0);
      expect(u.numeroProductos, 4);
      expect(u.idPropietario, 3);
      expect(u.propietario, 'Logística Integral');
      expect(u.manejoPropietario, true);

      expect(u.productos.length, 1);
      final prod = u.productos.first;
      expect(prod.id, 101);
      expect(prod.producto, 'Martillo');
      expect(prod.cantidad, 25.0);
      expect(prod.reservado, 5.0);
      expect(prod.cantidadMano, 30.0);
      expect(prod.lote, 'LOT-1');
      expect(prod.idPropietario, 3);
      expect(prod.propietario, 'Logística Integral');
      expect(prod.manejoPropietario, true);
    });

    test('parsea PaqueteInfo con productos y atributos de paquete', () {
      final resultMap = {
        'code': 200,
        'type': 'paquete',
        'result': {
          'id': 501,
          'nombre': 'PACK-2026-0001',
          'codigo_barras': 'PKG0001',
          'total_productos': 50.0,
          'numero_productos': 2,
          'is_certificate': true,
          'nombre_almacen': 'Almacén Despachos',
          'fecha_empaquetado': '2026-10-07 14:30',
          'productos': [
            {
              'id': 101,
              'producto': 'Martillo',
              'codigo_barras': '7709998881112',
              'cantidad': 50.0,
            }
          ],
        },
      };

      final info = InfoRapidaRemoteModel.fromResultMap(resultMap);

      expect(info, isA<PaqueteInfo>());
      final pq = info as PaqueteInfo;
      expect(pq.id, 501);
      expect(pq.nombre, 'PACK-2026-0001');
      expect(pq.codigoBarras, 'PKG0001');
      expect(pq.totalProductos, 50.0);
      expect(pq.numeroProductos, 2);
      expect(pq.isCertificate, true);
      expect(pq.nombreAlmacen, 'Almacén Despachos');
      expect(pq.fechaEmpaquetado, '2026-10-07 14:30');
      expect(pq.productos.length, 1);
      expect(pq.productos.first.id, 101);
      expect(pq.productos.first.producto, 'Martillo');
    });

    test('infiere tipo ProductoInfo cuando type no viene pero tiene ubicaciones', () {
      final resultMap = {
        'code': 200,
        'result': {
          'id': 102,
          'nombre': 'Destornillador',
          'ubicaciones': [],
        },
      };

      final info = InfoRapidaRemoteModel.fromResultMap(resultMap);
      expect(info, isA<ProductoInfo>());
    });

    test('infiere tipo PaqueteInfo cuando tiene productos e is_certificate', () {
      final resultMap = {
        'code': 200,
        'result': {
          'id': 502,
          'nombre': 'CAJA-1',
          'is_certificate': true,
          'productos': [],
        },
      };

      final info = InfoRapidaRemoteModel.fromResultMap(resultMap);
      expect(info, isA<PaqueteInfo>());
    });

    test('infiere tipo UbicacionInfo cuando tiene productos pero no indicadores de paquete', () {
      final resultMap = {
        'code': 200,
        'result': {
          'id': 206,
          'nombre': 'Estante B',
          'productos': [],
        },
      };

      final info = InfoRapidaRemoteModel.fromResultMap(resultMap);
      expect(info, isA<UbicacionInfo>());
    });
  });
}
