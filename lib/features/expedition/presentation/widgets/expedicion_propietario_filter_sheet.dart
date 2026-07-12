import 'package:flutter/material.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';

List<String> propietariosFromExpediciones(List<ExpedicionPedido> list) {
  return list
      .where((e) => e.propietario != null && e.propietario!.isNotEmpty)
      .map((e) => e.propietario!)
      .toSet()
      .toList()
    ..sort();
}

/// Bottom sheet para filtrar la lista de expediciones por propietario.
void showExpedicionPropietarioFilterSheet(
  BuildContext context, {
  required List<ExpedicionPedido> expediciones,
  required String? selected,
  required ValueChanged<String?> onSelected,
}) {
  final propietarios = propietariosFromExpediciones(expediciones);
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Filtrar por propietario',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            RadioListTile<String?>(
              title: const Text('Todos'),
              value: null,
              groupValue: selected,
              onChanged: (value) {
                onSelected(value);
                Navigator.pop(context);
              },
            ),
            ...propietarios.map((propietario) => RadioListTile<String?>(
                  title: Text(propietario),
                  value: propietario,
                  groupValue: selected,
                  onChanged: (value) {
                    onSelected(value);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      );
    },
  );
}
