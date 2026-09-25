import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// FAB temporal para previsualizar UpdateRequiredScreen. Solo se muestra en
/// debug. La pantalla es estática (no depende de datos del servidor), así
/// que no hace falta pasarle ningún argumento.
class UpdateRequiredTestFab extends StatelessWidget {
  const UpdateRequiredTestFab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return FloatingActionButton.small(
      heroTag: 'update_required_test_fab',
      backgroundColor: Colors.orange,
      tooltip: 'Probar UpdateRequiredScreen',
      onPressed: () => Navigator.pushNamed(context, 'update-required'),
      child: const Icon(Icons.system_update, color: Colors.white),
    );
  }
}
