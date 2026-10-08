import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Evita "Bad state: Cannot add new events after calling close".
///
/// Un `add()` que llega tarde (después de un `await` en un handler, desde un
/// stream, un timer o un `Future.then`) cuando la pantalla ya cerró el bloc
/// se descarta y queda en el log de Crashlytics en vez de tirar la app.
///
/// Por qué no alcanza con `isClosed`: en bloc 9.2.0 `isClosed` mira el
/// controlador de estados, que se cierra al FINAL de `close()`, después de
/// esperar a los handlers en curso. Mientras tanto el controlador de eventos
/// ya está cerrado: un `add()` desde ese handler lanza la excepción aunque
/// `isClosed` siga en `false`. [isClosing] se marca al empezar `close()`.
///
/// `emit()` en ese intervalo no es problema: la librería cancela los
/// emitters al cerrar y los ignora.
mixin SafeBlocMixin<E, S> on Bloc<E, S> {
  bool _closing = false;

  /// `true` desde que se llamó a `close()`, aunque todavía no terminó.
  /// Usarlo antes de encadenar eventos con `add()` después de un `await`.
  bool get isClosing => _closing || isClosed;

  @override
  Future<void> close() {
    _closing = true;
    return super.close();
  }

  @override
  void add(E event) {
    if (isClosing) {
      _logDropped('$runtimeType ← ${event.runtimeType}');
      return;
    }
    super.add(event);
  }
}

void _logDropped(String detail) {
  debugPrint('⚠️ add tras close descartado: $detail');
  try {
    FirebaseCrashlytics.instance.log('add tras close: $detail');
  } catch (_) {
    // Firebase sin inicializar (tests): alcanza con el debugPrint.
  }
}
