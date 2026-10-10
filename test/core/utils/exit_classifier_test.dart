import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/core/utils/diagnostics/exit_classifier.dart';

void main() {
  const latido = 1_000_000;

  SalidaAndroid salida(
    String reason, {
    int timestamp = latido + 20000,
    String description = 'crash',
  }) =>
      SalidaAndroid(
        reason: reason,
        description: description,
        timestamp: timestamp,
        importance: 100,
      );

  group('salidaDeSesionPrevia', () {
    test('toma la primera salida posterior al último latido', () {
      final vieja = salida('CRASH', timestamp: latido - 60000);
      final primera = salida('CRASH', timestamp: latido + 10000);
      final segunda = salida('ANR', timestamp: latido + 90000);

      expect(
        salidaDeSesionPrevia([segunda, vieja, primera], latido),
        same(primera),
      );
    });

    test('acepta una salida apenas anterior al latido (relojes distintos)', () {
      final s = salida('CRASH', timestamp: latido - 2000);
      expect(salidaDeSesionPrevia([s], latido), same(s));
    });

    test('sin salidas posteriores o sin latido → null', () {
      expect(
        salidaDeSesionPrevia([salida('CRASH', timestamp: latido - 60000)], latido),
        isNull,
      );
      expect(salidaDeSesionPrevia([salida('CRASH')], null), isNull);
    });
  });

  group('clasificarCierrePrevio', () {
    test('pasó por segundo plano o salió a propósito → no se reporta', () {
      for (final estado in ['paused', 'hidden', 'detached', 'exit', null]) {
        expect(
          clasificarCierrePrevio(
            ultimoEstado: estado,
            salida: salida('CRASH'),
            soReportaSalidas: true,
          ),
          isNull,
          reason: 'estado $estado',
        );
      }
    });

    test('con motivo de Android → un issue por motivo', () {
      final crash = clasificarCierrePrevio(
        ultimoEstado: 'resumed',
        salida: salida('CRASH'),
        soReportaSalidas: true,
      );
      final lmk = clasificarCierrePrevio(
        ultimoEstado: 'inactive',
        salida: salida('LOW_MEMORY'),
        soReportaSalidas: true,
      );

      expect(crash!.grupo, 'cierre_CRASH');
      expect(crash.titulo, contains('[CRASH]'));
      expect(lmk!.grupo, 'cierre_LOW_MEMORY');
    });

    test('motivo benigno con la app abierta (p. ej. actualización) → nada', () {
      expect(
        clasificarCierrePrevio(
          ultimoEstado: 'resumed',
          salida: salida('PACKAGE_UPDATED'),
          soReportaSalidas: true,
        ),
        isNull,
      );
    });

    test('Android 11+ sin registro de salida → equipo apagado', () {
      expect(
        clasificarCierrePrevio(
          ultimoEstado: 'resumed',
          salida: null,
          soReportaSalidas: true,
        )!.grupo,
        'cierre_equipo_apagado',
      );
    });

    test('Android < 11 sin motivo → cierre sin motivo', () {
      expect(
        clasificarCierrePrevio(
          ultimoEstado: 'resumed',
          salida: null,
          soReportaSalidas: false,
        )!.grupo,
        'cierre_sin_motivo',
      );
    });
  });

  group('SalidaAndroid', () {
    test('benignas: motivos normales y proceso en caché liberado', () {
      expect(salida('USER_STOPPED').esBenigna, isTrue);
      expect(
        salida('OTHER', description: 'empty for too long').esBenigna,
        isTrue,
      );
      expect(salida('OTHER', description: 'otro').esBenigna, isFalse);
      expect(salida('LOW_MEMORY').esBenigna, isFalse);
    });

    test('fromMap lee los tipos del canal', () {
      final s = SalidaAndroid.fromMap({
        'reason': 'ANR',
        'description': 'input dispatching timed out',
        'timestamp': 123,
        'importance': 100,
        'rss': 327632,
        'pss': 200971,
      });
      expect(s.reason, 'ANR');
      expect(s.timestamp, 123);
      expect(s.rss, 327632);
    });
  });

  test('pilaDeGrupo: un frame con el nombre del grupo (agrupa en Crashlytics)',
      () {
    final pila = pilaDeGrupo('cierre_CRASH').toString();
    expect(pila, startsWith('#0      ExitDiagnostics.cierre_CRASH ('));
    expect(pila.trim().split('\n'), hasLength(1));
    expect(pilaDeGrupo('cierre_ANR').toString(), isNot(pila));
  });
}
