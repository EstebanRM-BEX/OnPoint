import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/scan/packing_scan_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';

/// Cantidad menor a la de la línea: aceptar con novedad (el faltante queda
/// para backorder, foto opcional) o dividir (el resto queda por hacer).
Future<void> showDecisionParcialDialog(
  BuildContext context,
  PackingScanBloc bloc,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        BlocProvider.value(value: bloc, child: const _DecisionParcialDialog()),
  );
}

class _DecisionParcialDialog extends StatefulWidget {
  const _DecisionParcialDialog();

  @override
  State<_DecisionParcialDialog> createState() => _DecisionParcialDialogState();
}

class _DecisionParcialDialogState extends State<_DecisionParcialDialog> {
  String? _novedad;
  bool _fotoEnviada = false;

  Future<void> _tomarFoto() async {
    final foto = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (foto == null || !mounted) return;
    context.read<PackingScanBloc>().add(ImagenNovedadPackEnviada(foto.path));
    setState(() => _fotoEnviada = true);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PackingScanBloc>();
    final s = bloc.state;
    final cantidad = s.cantidadEnDecision ?? 0;
    final total = s.producto?.quantity ?? 0;
    final fmt = PackFormatos.cantidad;

    return AlertDialog(
      backgroundColor: white,
      title: Text(
        'Cantidad menor a la solicitada',
        textAlign: TextAlign.center,
        style: TextStyle(color: primaryColorApp, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14, color: black),
                children: [
                  const TextSpan(text: 'Va a separar '),
                  TextSpan(
                    text: fmt(cantidad),
                    style: const TextStyle(
                      color: red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' de '),
                  TextSpan(
                    text: fmt(total),
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            const Text(
              'Aceptar con novedad: el faltante queda para backorder.',
              style: TextStyle(fontSize: 12, color: grey),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _novedad,
              hint: const Text('Seleccione la novedad'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final n in s.novedades)
                  DropdownMenuItem(value: n.name, child: Text(n.name)),
              ],
              onChanged: (v) => setState(() => _novedad = v),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _tomarFoto,
                icon: Icon(
                  _fotoEnviada ? Icons.check_circle : Icons.photo_camera,
                  color: _fotoEnviada ? green : primaryColorApp,
                ),
                label: Text(
                  _fotoEnviada
                      ? 'Foto enviada'
                      : 'Foto de evidencia (opcional)',
                  style: TextStyle(color: primaryColorApp, fontSize: 12),
                ),
              ),
            ),
            const Divider(),
            const Text(
              'Dividir: separa esta cantidad y el resto queda en por hacer.',
              style: TextStyle(fontSize: 12, color: grey),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () {
            bloc.add(const DecisionParcialPackCancelada());
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            bloc.add(const DivisionPackSolicitada());
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: grey),
          child: const Text('Dividir', style: TextStyle(color: white)),
        ),
        ElevatedButton(
          onPressed: _novedad == null
              ? null
              : () {
                  bloc.add(SeparacionParcialPackAceptada(_novedad!));
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(backgroundColor: primaryColorApp),
          child: const Text('Aceptar', style: TextStyle(color: white)),
        ),
      ],
    );
  }
}
