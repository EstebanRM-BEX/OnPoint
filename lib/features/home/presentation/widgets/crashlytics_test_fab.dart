import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// FAB temporal para validar Crashlytics. Solo se muestra en debug.
/// El reporte llega a Firebase al volver a abrir la app tras el crash.
class CrashlyticsTestFab extends StatelessWidget {
  const CrashlyticsTestFab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return FloatingActionButton.small(
      heroTag: 'crashlytics_test_fab',
      backgroundColor: Colors.red,
      tooltip: 'Probar Crashlytics',
      onPressed: () => _confirmCrash(context),
      child: const Icon(Icons.bug_report, color: Colors.white),
    );
  }

  Future<void> _confirmCrash(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Probar Crashlytics'),
        content: const Text(
          'La app se cerrará. Vuelve a abrirla para que el reporte se envíe a Firebase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Forzar crash'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    FirebaseCrashlytics.instance.log('Crash de prueba desde Home');
    FirebaseCrashlytics.instance.crash();
  }
}
