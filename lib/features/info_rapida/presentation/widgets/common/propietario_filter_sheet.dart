import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_snackbar.dart';

/// Resultado del filtro: `propietario == null` es "Todos los propietarios".
typedef PropietarioSeleccion = ({String? propietario});

/// Hoja inferior para filtrar por propietario. Devuelve null si se cierra sin
/// elegir. Si no hay propietarios avisa y no abre nada.
Future<PropietarioSeleccion?> showPropietarioFilterSheet(
  BuildContext context, {
  required List<String> propietarios,
  required String? seleccionado,
}) async {
  if (propietarios.isEmpty) {
    InfoRapidaSnackbar.info(
      'Sin propietarios',
      'No hay productos con propietario para filtrar',
    );
    return null;
  }

  return showModalBottomSheet<PropietarioSeleccion>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      Widget opcion(String? valor, String label) => ListTile(
        leading: Icon(
          seleccionado == valor
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: primaryColorApp,
        ),
        title: Text(label),
        onTap: () => Navigator.pop(sheetContext, (propietario: valor)),
      );

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: primaryColorApp),
                  SizedBox(width: 8),
                  Text(
                    'Filtrar por propietario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColorApp,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  opcion(null, 'Todos los propietarios'),
                  for (final p in propietarios) opcion(p, p),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
