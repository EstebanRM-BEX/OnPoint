import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/features/info_rapida/data/models/recent_query_model.dart';
import 'package:wms_app/features/info_rapida/domain/entities/recent_query.dart';

void main() {
  final testDate = DateTime(2026, 10, 8, 8, 30);

  final testEntity = RecentQuery(
    query: '7701234567890',
    isManual: false,
    isProduct: true,
    type: 'product',
    title: 'PROD-001',
    subtitle: 'Tornillo Hexagonal 3/8',
    badge: '120 un.',
    date: testDate,
  );

  group('RecentQueryModel', () {
    test('fromEntity y toEntity deben preservar exactamente los datos', () {
      final model = RecentQueryModel.fromEntity(testEntity);
      expect(model.toEntity(), testEntity);
    });

    test('toJson y fromJson deben serializar y deserializar correctamente', () {
      final model = RecentQueryModel(testEntity);
      final jsonMap = model.toJson();

      expect(jsonMap['query'], '7701234567890');
      expect(jsonMap['isManual'], false);
      expect(jsonMap['isProduct'], true);
      expect(jsonMap['type'], 'product');
      expect(jsonMap['title'], 'PROD-001');
      expect(jsonMap['subtitle'], 'Tornillo Hexagonal 3/8');
      expect(jsonMap['badge'], '120 un.');
      expect(jsonMap['date'], testDate.toIso8601String());

      final restoredModel = RecentQueryModel.fromJson(jsonMap);
      expect(restoredModel.toEntity(), testEntity);
    });

    test('fromJson maneja campos nulos o ausentes con defaults seguros', () {
      final restored = RecentQueryModel.fromJson(const {});
      final entity = restored.toEntity();

      expect(entity.query, '');
      expect(entity.isManual, false);
      expect(entity.isProduct, false);
      expect(entity.type, '');
      expect(entity.title, '');
      expect(entity.subtitle, '');
      expect(entity.badge, isNull);
      expect(entity.date, isNotNull);
    });

    test('dedupeKey genera la clave en mayúsculas combinada con type', () {
      expect(testEntity.dedupeKey, 'product|PROD-001');

      final locQuery = RecentQuery(
        query: 'loc1',
        isManual: true,
        isProduct: false,
        type: 'ubicacion',
        title: 'pasillo a-01',
        subtitle: 'Almacén Principal',
        date: testDate,
      );
      expect(locQuery.dedupeKey, 'ubicacion|PASILLO A-01');
    });

    test('copyWith crea una nueva copia con los campos modificados', () {
      final updated = testEntity.copyWith(
        query: 'NEW-BARCODE',
        badge: '200 un.',
      );

      expect(updated.query, 'NEW-BARCODE');
      expect(updated.badge, '200 un.');
      expect(updated.title, testEntity.title);
      expect(updated.type, testEntity.type);
    });
  });
}
