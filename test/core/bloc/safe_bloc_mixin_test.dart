import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/core/bloc/safe_bloc_mixin.dart';

class _Inc {}

class _Start {}

class _CounterBloc extends Bloc<Object, int> with SafeBlocMixin<Object, int> {
  _CounterBloc(this.gate) : super(0) {
    on<_Inc>((_, emit) => emit(state + 1));
    // Simula un handler que espera (SQLite/red) y después encadena un evento.
    on<_Start>((_, emit) async {
      await gate.future;
      add(_Inc());
    });
  }

  final Completer<void> gate;
}

void main() {
  test('add() después de close() no lanza y descarta el evento', () async {
    final bloc = _CounterBloc(Completer());
    await bloc.close();

    expect(() => bloc.add(_Inc()), returnsNormally);
    expect(bloc.state, 0);
  });

  test('add() desde un handler en curso mientras se cierra no lanza', () async {
    final gate = Completer<void>();
    final bloc = _CounterBloc(gate)..add(_Start());
    await Future<void>.delayed(Duration.zero);

    final closing = bloc.close();
    expect(bloc.isClosing, isTrue);
    gate.complete();

    await expectLater(closing, completes);
    expect(bloc.state, 0);
  });

  test('add() con el bloc abierto procesa el evento', () async {
    final bloc = _CounterBloc(Completer());
    bloc.add(_Inc());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, 1);
    expect(bloc.isClosing, isFalse);
    await bloc.close();
  });
}
