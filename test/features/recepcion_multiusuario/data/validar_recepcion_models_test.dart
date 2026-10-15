import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_session_model.dart';
import 'package:wms_app/features/recepcion_multiusuario/data/models/recepcion_validacion_model.dart';

void main() {
  group('RecepcionSessionModel: campos del validador', () {
    test('lee validator_*, lines_assigned y can_validate_document', () {
      final s = RecepcionSessionModel.fromJson({
        'id': 15,
        'state': 'open',
        'validator_id': 42,
        'validator_name': 'Ana Validador',
        'lines_assigned': 2,
        'current_user_can_be_validator': true,
        'current_user_is_validator': true,
        'can_validate_document': false,
      });
      expect(s.validatorId, 42);
      expect(s.validatorName, 'Ana Validador');
      expect(s.linesAssigned, 2);
      expect(s.currentUserCanBeValidator, isTrue);
      expect(s.currentUserIsValidator, isTrue);
      expect(s.canValidateDocument, isFalse);
    });

    test('backend anterior sin los campos: quedan en null', () {
      final s = RecepcionSessionModel.fromJson({'id': 15});
      expect(s.currentUserIsValidator, isNull);
      expect(s.canValidateDocument, isNull);
      expect(s.linesAssigned, isNull);
    });

    test('validator_name false de Odoo se lee como null', () {
      final s = RecepcionSessionModel.fromJson({
        'validator_id': 0,
        'validator_name': false,
      });
      expect(s.validatorId, 0);
      expect(s.validatorName, isNull);
    });
  });

  test('validator_id/name se guardan y se leen de SQLite', () {
    final s = RecepcionSessionModel.fromJson({
      'id': 15,
      'validator_id': 42,
      'validator_name': 'Ana Validador',
      'can_validate_document': true,
    });
    final local = RecepcionSessionModel.fromMap(s.toMap());
    expect(local.validatorId, 42);
    expect(local.validatorName, 'Ana Validador');
    // El resto de los flags no se persiste: se lee fresco del backend.
    expect(local.canValidateDocument, isNull);
  });

  group('RecepcionValidacionModel', () {
    test('completada con backorder', () {
      final v = RecepcionValidacionModel.fromJson({
        'session_state': 'done',
        'picking_state': 'done',
        'picking_name': 'WH/IN/00088',
        'backorder_id': 91,
        'backorder_name': 'WH/IN/00091',
      }, message: 'Sesión multi y picking validados.');
      expect(v.completada, isTrue);
      expect(v.tieneBackorder, isTrue);
      expect(v.backorderName, 'WH/IN/00091');
      expect(v.message, 'Sesión multi y picking validados.');
    });

    test('backorder_id 0: se recibió todo', () {
      final v = RecepcionValidacionModel.fromJson({
        'session_state': 'done',
        'picking_state': 'done',
        'backorder_id': 0,
        'backorder_name': false,
      });
      expect(v.tieneBackorder, isFalse);
      expect(v.backorderName, isNull);
    });

    test('no es éxito si el picking no quedó en done', () {
      final v = RecepcionValidacionModel.fromJson({
        'session_state': 'done',
        'picking_state': 'assigned',
      });
      expect(v.completada, isFalse);
    });
  });
}
