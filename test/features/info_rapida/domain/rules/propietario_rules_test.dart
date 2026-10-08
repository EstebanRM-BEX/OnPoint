import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/features/info_rapida/domain/rules/propietario_rules.dart';

void main() {
  group('PropietarioRules', () {
    group('normalizeKey', () {
      test('retorna null si tieneManejoPropietario es null o false', () {
        expect(
          PropietarioRules.normalizeKey(
            tieneManejoPropietario: null,
            propietario: 'Empresa A',
          ),
          isNull,
        );
        expect(
          PropietarioRules.normalizeKey(
            tieneManejoPropietario: false,
            propietario: 'Empresa A',
          ),
          isNull,
        );
      });

      test('retorna null si propietario es null, vacío o solo espacios', () {
        expect(
          PropietarioRules.normalizeKey(
            tieneManejoPropietario: true,
            propietario: null,
          ),
          isNull,
        );
        expect(
          PropietarioRules.normalizeKey(
            tieneManejoPropietario: true,
            propietario: '',
          ),
          isNull,
        );
        expect(
          PropietarioRules.normalizeKey(
            tieneManejoPropietario: true,
            propietario: '   ',
          ),
          isNull,
        );
      });

      test('retorna null si propietario es el string "false" (legacy backend)', () {
        expect(
          PropietarioRules.normalizeKey(
            tieneManejoPropietario: true,
            propietario: 'false',
          ),
          isNull,
        );
        expect(
          PropietarioRules.normalizeKey(
            tieneManejoPropietario: true,
            propietario: 'FALSE',
          ),
          isNull,
        );
      });

      test('retorna el propietario recortado cuando tiene manejo y nombre válido', () {
        expect(
          PropietarioRules.normalizeKey(
            tieneManejoPropietario: true,
            propietario: '  Cliente Principal SAS  ',
          ),
          equals('Cliente Principal SAS'),
        );
      });
    });

    group('sonCompatibles', () {
      test('dos productos sin propietario son compatibles', () {
        expect(PropietarioRules.sonCompatibles(null, null), isTrue);
      });

      test('dos productos con el mismo propietario son compatibles', () {
        expect(
          PropietarioRules.sonCompatibles('Propietario X', 'Propietario X'),
          isTrue,
        );
      });

      test('uno sin propietario y otro con propietario no son compatibles', () {
        expect(
          PropietarioRules.sonCompatibles(null, 'Propietario X'),
          isFalse,
        );
        expect(
          PropietarioRules.sonCompatibles('Propietario X', null),
          isFalse,
        );
      });

      test('dos propietarios distintos no son compatibles', () {
        expect(
          PropietarioRules.sonCompatibles('Propietario A', 'Propietario B'),
          isFalse,
        );
      });
    });

    group('validarCompatibilidad', () {
      test('retorna null cuando son compatibles', () {
        expect(
          PropietarioRules.validarCompatibilidad(
            keyExistente: null,
            keyNuevo: null,
          ),
          isNull,
        );
        expect(
          PropietarioRules.validarCompatibilidad(
            keyExistente: 'Propietario A',
            keyNuevo: 'Propietario A',
          ),
          isNull,
        );
      });

      test('informa error adecuado al mezclar sin propietario con un propietario', () {
        final error = PropietarioRules.validarCompatibilidad(
          keyExistente: null,
          keyNuevo: 'Cliente XYZ',
        );
        expect(
          error,
          equals(
            'No puedes mezclar productos sin propietario con productos de "Cliente XYZ"',
          ),
        );
      });

      test('informa error adecuado al mezclar un propietario con sin propietario', () {
        final error = PropietarioRules.validarCompatibilidad(
          keyExistente: 'Cliente XYZ',
          keyNuevo: null,
        );
        expect(
          error,
          equals(
            'No puedes mezclar productos de "Cliente XYZ" con productos sin propietario',
          ),
        );
      });

      test('informa error adecuado al mezclar dos propietarios diferentes', () {
        final error = PropietarioRules.validarCompatibilidad(
          keyExistente: 'Cliente A',
          keyNuevo: 'Cliente B',
        );
        expect(
          error,
          equals(
            'No puedes mezclar productos de "Cliente A" con productos de "Cliente B"',
          ),
        );
      });
    });
  });
}
