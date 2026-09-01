import 'dart:ui';

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

    // Mismo diseño que DialogOrderAdvetenciaCantidadScreen (recepción
    // individual): blur de fondo, Cancelar/Aceptar en las actions del
    // AlertDialog en vez de dentro del content.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: white,
        title: Center(
          child: Text(
            '360 Software Informa',
            textAlign: TextAlign.center,
            style: TextStyle(color: yellow, fontSize: 18),
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
                            text: 'La cantidad a registrar ',
                            style: TextStyle(color: black, fontSize: 12),
                          ),
                          TextSpan(
                            text: '${widget.cantidad} ',
                            style: TextStyle(
                              color: primaryColorApp,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text: 'es menor a lo pendiente ',
                            style: TextStyle(color: black, fontSize: 12),
                          ),
                          TextSpan(
                            text: '${widget.pendiente}',
                            style: TextStyle(
                              color: green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text: '.',
                            style: TextStyle(color: black, fontSize: 12),
                          ),
                        ]
                      : [
                          const TextSpan(
                            text: 'Vas a registrar ',
                            style: TextStyle(color: black, fontSize: 12),
                          ),
                          TextSpan(
                            text: '${widget.cantidad}',
                            style: TextStyle(
                              color: primaryColorApp,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(
                            text: ' unidades.',
                            style: TextStyle(color: black, fontSize: 12),
                          ),
                        ],
                ),
              ),
              const Text(
                'Para continuar, seleccione la novedad o divida la cantidad del producto',
                textAlign: TextAlign.center,
                style: TextStyle(color: black, fontSize: 12),
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
                    minimumSize: Size(size.width * 0.6, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Dividir Cantidad',
                    style: TextStyle(fontSize: 14, color: white),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(size.width * 0.3, 30),
              backgroundColor: white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            child: Text('Cancelar', style: TextStyle(color: primaryColorApp)),
          ),
          ElevatedButton(
            onPressed: _selected == null
                ? null
                : () => Navigator.pop(context, _selected!.name),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              minimumSize: Size(size.width * 0.3, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            child: const Text('Aceptar', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }
}
