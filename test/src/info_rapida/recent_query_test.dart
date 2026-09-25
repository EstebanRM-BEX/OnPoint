import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/src/presentation/views/info_rapida/data/recent_queries_store.dart';
import 'package:wms_app/src/presentation/views/info_rapida/models/info_rapida_model.dart';

void main() {
  RecentQuery build(String type, InfoResult info, {String query = 'X1'}) =>
      RecentQuery.fromResult(
        query: query,
        isManual: false,
        isProduct: false,
        result: InfoRapidaResult(type: type, result: info),
      );

  test('producto: referencia como título, nombre y cantidad con unidad', () {
    final q = build(
      'product',
      InfoResult(
        referencia: 'SKU-1',
        nombre: 'Tornillo',
        cantidadDisponible: 1420,
        unidadMedida: 'Und',
      ),
    );
    expect(q.title, 'SKU-1');
    expect(q.subtitle, 'Tornillo');
    expect(q.badge, '1420 Und');
  });

  test('producto sin referencia ni código cae al texto consultado', () {
    final q = build('product', InfoResult(nombre: 'Tornillo'), query: '7701');
    expect(q.title, '7701');
    expect(q.badge, isNull);
  });

  test('valores false/null del backend no se muestran', () {
    final q = build(
      'ubicacion',
      InfoResult(nombre: 'A-01', nombreAlmacen: 'false', ubicacionPadre: null),
    );
    expect(q.subtitle, isEmpty);
  });

  test('ubicación: almacén y padre en el subtítulo', () {
    final q = build(
      'ubicacion',
      InfoResult(
        nombre: 'A-01',
        nombreAlmacen: 'Principal',
        ubicacionPadre: 'Zona B',
        numeroProductos: 84,
      ),
    );
    expect(q.subtitle, 'Principal • Zona B');
    expect(q.badge, '84 prod.');
  });

  test('ida y vuelta JSON conserva los parámetros para repetir la consulta',
      () {
    final q = RecentQuery(
      query: '15',
      isManual: true,
      isProduct: true,
      type: 'product',
      title: 'SKU-1',
      subtitle: 'Tornillo',
      date: DateTime(2026, 9, 21),
    );
    final back = RecentQuery.fromJson(q.toJson());
    expect(back.query, '15');
    expect(back.isManual, isTrue);
    expect(back.isProduct, isTrue);
    expect(back.dedupeKey, q.dedupeKey);
  });
}
