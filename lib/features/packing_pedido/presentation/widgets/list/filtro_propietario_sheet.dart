import 'package:flutter/material.dart';

/// Hoja inferior para elegir propietario (null = todos).
Future<void> showFiltroPropietarioSheet(
  BuildContext context, {
  required List<String> propietarios,
  required String? actual,
  required ValueChanged<String?> onElegido,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por propietario',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            for (final p in [null, ...propietarios])
              RadioListTile<String?>(
                title: Text(p ?? 'Todos'),
                value: p,
                groupValue: actual,
                onChanged: (v) {
                  onElegido(v);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    ),
  );
}
