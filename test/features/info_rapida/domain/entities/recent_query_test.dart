import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';

void main() {
  final fecha = DateTime(2026, 10, 8);

  group('RecentQuery.fromInfo (formato del legacy)', () {
    test('producto: título por referencia, subtítulo nombre, badge cantidad',
        () {
      final q = RecentQuery.fromInfo(
        query: '770001',
        isManual: false,
        date: fecha,
        info: const ProductoInfo(
          id: 1,
          nombre: 'Tornillo M6',
          referencia: 'REF-1',
          codigoBarras: '770001',
          cantidadDisponible: 12,
          unidadMedida: 'Und',
        ),
      );

      expect(q.type, 'product');
      expect(q.isProduct, isTrue);
      expect(q.title, 'REF-1');
      expect(q.subtitle, 'Tornillo M6');
      expect(q.badge, '12 Und');
    });

    test('producto sin referencia usa el código de barras y "un." por defecto',
        () {
      final q = RecentQuery.fromInfo(
        query: '770001',
        isManual: false,
        date: fecha,
        info: const ProductoInfo(
          id: 1,
          nombre: 'Tornillo',
          codigoBarras: '770001',
          cantidadDisponible: 2.5,
        ),
      );

      expect(q.title, '770001');
      expect(q.badge, '2.5 un.');
    });

    test('ubicación: almacén • padre y número de productos', () {
      final q = RecentQuery.fromInfo(
        query: '10',
        isManual: true,
        date: fecha,
        info: const UbicacionInfo(
          id: 10,
          nombre: 'A1-01',
          nombreAlmacen: 'Central',
          ubicacionPadre: 'A1',
          numeroProductos: 3,
        ),
      );

      expect(q.type, 'ubicacion');
      expect(q.isProduct, isFalse);
      expect(q.isManual, isTrue);
      expect(q.title, 'A1-01');
      expect(q.subtitle, 'Central • A1');
      expect(q.badge, '3 prod.');
    });

    test('paquete: usa total de productos si no hay número', () {
      final q = RecentQuery.fromInfo(
        query: 'PACK1',
        isManual: false,
        date: fecha,
        info: const PaqueteInfo(nombre: 'PACK1', totalProductos: 8),
      );

      expect(q.type, 'paquete');
      expect(q.badge, '8 prod.');
    });
  });
}
