import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';

/// Diálogo que se muestra al presionar "APLICAR CANTIDAD" en
/// scan_product_screen.dart cuando la cantidad ingresada es MENOR a lo
/// pendiente del claim. A diferencia de recepción individual (que ofrece
/// "Aceptar" o "Dividir" en backorder), acá no existe el concepto de
/// backorder todavía: hay que elegir una novedad que explique la diferencia
/// ("CONFIRMAR"), o saltarse ese paso con "DIVIDIR", que envía directo con
/// la observación fija "Sin novedad" — la cantidad ya fue elegida en la
/// pantalla anterior, este diálogo no la vuelve a pedir.
///
/// Devuelve el texto de la observación a enviar vía
/// `Navigator.pop(context, observacion)`, o `null` si el operario cancela.
class RecepcionSelectNovedadDialog extends StatefulWidget {
  const RecepcionSelectNovedadDialog({
    super.key,
    required this.cantidad,
    required this.pendiente,
    required this.novedades,
    required this.mostrarCantidadPendiente,
  });

  final double cantidad;
  final double pendiente;
  final List<Novedad> novedades;

  /// Espejo del permiso hideExpectedQty (tbl_configurations): si está
  /// desactivado, no se debe mostrar cuánto era lo pendiente — solo la
  /// cantidad que se va a registrar.
  final bool mostrarCantidadPendiente;

  @override
  State<RecepcionSelectNovedadDialog> createState() =>
      _RecepcionSelectNovedadDialogState();
}

class _RecepcionSelectNovedadDialogState
    extends State<RecepcionSelectNovedadDialog> {
  Novedad? _selected;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return AlertDialog(
      title: Center(
        child: Text(
          'Cantidad incompleta',
          style: TextStyle(color: primaryColorApp, fontSize: 16),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: widget.mostrarCantidadPendiente
                    ? [
                        const TextSpan(
                          text: 'Vas a registrar ',
                          style: TextStyle(fontSize: 13, color: black),
                        ),
                        TextSpan(
                          text: '${widget.cantidad} ',
                          style: TextStyle(
                            fontSize: 13,
                            color: primaryColorApp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: 'de ',
                          style: TextStyle(fontSize: 13, color: black),
                        ),
                        TextSpan(
                          text: '${widget.pendiente} ',
                          style: TextStyle(
                            fontSize: 13,
                            color: primaryColorApp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text:
                              'pendientes. Seleccione una novedad para continuar.',
                          style: TextStyle(fontSize: 13, color: black),
                        ),
                      ]
                    : [
                        const TextSpan(
                          text: 'Vas a registrar ',
                          style: TextStyle(fontSize: 13, color: black),
                        ),
                        TextSpan(
                          text: '${widget.cantidad} ',
                          style: TextStyle(
                            fontSize: 13,
                            color: primaryColorApp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text:
                              'unidades. Seleccione una novedad para continuar.',
                          style: TextStyle(fontSize: 13, color: black),
                        ),
                      ],
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<Novedad>(
                  underline: Container(height: 0),
                  borderRadius: BorderRadius.circular(10),
                  focusColor: white,
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
                      color: primaryColorApp,
                      'assets/icons/novedad.svg',
                      height: 20,
                      width: 20,
                      fit: BoxFit.cover,
                    ),
                  ),
                  value: _selected,
                  alignment: Alignment.centerLeft,
                  style: const TextStyle(color: black, fontSize: 14),
                  items: widget.novedades
                      .map(
                        (novedad) => DropdownMenuItem<Novedad>(
                          value: novedad,
                          child: Text(novedad.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selected = value),
                ),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, 'Sin novedad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: grey,
                  minimumSize: const Size(double.infinity, 35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('DIVIDIR', style: TextStyle(fontSize: 14, color: white)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: grey,
                      minimumSize: const Size(double.infinity, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(color: white, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.pop(context, _selected!.name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorApp,
                      minimumSize: const Size(double.infinity, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'CONFIRMAR',
                      style: TextStyle(color: white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: 16,
      ),
    );
  }
}
