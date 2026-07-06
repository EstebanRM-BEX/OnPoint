import 'dart:async';

import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// Configuración global de los widget tests.
///
/// Habilita leak_tracker en toda la suite: cualquier ChangeNotifier
/// (TextEditingController, FocusNode, ScrollController, etc.) instrumentado
/// por Flutter que quede sin dispose al terminar un testWidgets hace fallar
/// el test con el stack trace de dónde se creó.
///
/// Para ignorar un leak conocido en un test puntual:
///   testWidgets('...', experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(), ...)
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LeakTesting.enable();
  await testMain();
}
