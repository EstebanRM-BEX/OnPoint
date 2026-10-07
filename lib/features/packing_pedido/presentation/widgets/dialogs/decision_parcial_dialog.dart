import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/scan/packing_scan_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_photo_novedad_widget.dart';

/// Cantidad menor a la de la línea, con el diseño del módulo anterior:
/// elegir la novedad (y opcionalmente una foto) para aceptar el faltante, o
/// dividir la cantidad.
Future<void> showDecisionParcialDialog(
  BuildContext context,
  PackingScanBloc bloc,
) async {
  final novedad = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        BlocProvider.value(value: bloc, child: const _DecisionParcialDialog()),
  );
  if (novedad == null) return;
  if (!context.mounted) return;

  var respondido = false;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          bloc.add(const DecisionParcialPackCancelada());
          Navigator.of(context).pop();
        }
      },
      child: DialogCapturaNovedad(
        onResult: (File? foto) {
          respondido = true;
          bloc.add(
            SeparacionParcialPackAceptada(novedad, imagePath: foto?.path),
          );
        },
      ),
    ),
  );

  if (!respondido) {
    bloc.add(const DecisionParcialPackCancelada());
  }
}

class _DecisionParcialDialog extends StatefulWidget {
  const _DecisionParcialDialog();

  @override
  State<_DecisionParcialDialog> createState() => _DecisionParcialDialogState();
}

class _DecisionParcialDialogState extends State<_DecisionParcialDialog> {
  String? _novedad;

  /// "Aceptar": cierra la decisión devolviendo la novedad seleccionada.
  void _aceptar() {
    Navigator.of(context).pop(_novedad);
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final bloc = context.read<PackingScanBloc>();
    final s = bloc.state;
    final cantidad = s.cantidadEnDecision ?? 0;
    final total = s.producto?.quantity ?? 0;
    final fmt = PackFormatos.cantidad;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: Colors.white,
        title: const Center(
          child: Text(
            '360 Software Informa',
            style: TextStyle(color: yellow, fontSize: 14),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'La cantidad separada ',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  TextSpan(
                    text: '${fmt(cantidad)} ',
                    style: TextStyle(
                      color: primaryColorApp,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: 'es menor a la cantidad a recoger ',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  TextSpan(
                    text: fmt(total),
                    style: const TextStyle(
                      color: green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Para continuar, seleccione la novedad o divida la cantidad del '
              'producto',
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DropdownButton<String>(
                  underline: Container(height: 0),
                  borderRadius: BorderRadius.circular(10),
                  focusColor: Colors.white,
                  isExpanded: true,
                  isDense: true,
                  hint: const Text(
                    'Seleccionar novedad',
                    style: TextStyle(fontSize: 14, color: black),
                  ),
                  icon: SizedBox(
                    height: 20,
                    width: 20,
                    child: SvgPicture.asset(
                      'assets/icons/novedad.svg',
                      colorFilter: ColorFilter.mode(
                        primaryColorApp,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  value: _novedad,
                  style: const TextStyle(color: black, fontSize: 14),
                  items: [
                    for (final n in s.novedades)
                      DropdownMenuItem<String>(
                        value: n.name,
                        child: Text(n.name),
                      ),
                  ],
                  onChanged: (v) => setState(() => _novedad = v),
                ),
              ),
            ),
            if (cantidad >= 1)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  bloc.add(const DivisionPackSolicitada());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: grey,
                  minimumSize: Size(ancho * 0.6, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Dividir Cantidad',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              bloc.add(const DecisionParcialPackCancelada());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size(ancho * 0.3, 30),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            child: Text('Cancelar', style: TextStyle(color: primaryColorApp)),
          ),
          ElevatedButton(
            onPressed: _novedad == null ? null : _aceptar,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              minimumSize: Size(ancho * 0.3, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
