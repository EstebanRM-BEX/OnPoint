// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';

class DialogAdvetenciaCantidadScreen extends StatefulWidget {
  const DialogAdvetenciaCantidadScreen({
    super.key,
    required this.cantidad,
    required this.productQuantity,
    required this.onAccepted,
    required this.batchId,
    required this.novedades,
  });

  final double cantidad; // Variable para almacenar la cantidad
  final num productQuantity; // Cantidad solicitada del producto
  final int batchId; // Variable para almacenar el id del lote
  final Future<void> Function(String selectedNovedad)
      onAccepted; // Callback modificado para recibir la novedad
  final List<Novedad> novedades; // Lista de novedades inyectada dinámicamente

  @override
  State<DialogAdvetenciaCantidadScreen> createState() =>
      _DialogAdvetenciaCantidadScreenState();
}

class _DialogAdvetenciaCantidadScreenState
    extends State<DialogAdvetenciaCantidadScreen> {
  String? selectedNovedad; // Variable para almacenar la opción seleccionada

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: Colors.white,
        title: const Center(
            child: Text('360 Software Informa',
                style: TextStyle(color: yellow, fontSize: 14))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'La cantidad separada ',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 14), // Color del texto normal
                  ),
                  TextSpan(
                    text: '${widget.cantidad} ',
                    style: TextStyle(
                      color: primaryColorApp,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    // Color rojo para quantity
                  ),
                  const TextSpan(
                    text: 'es menor a la cantidad a recoger ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ), // Color del texto normal
                  ),
                  TextSpan(
                    text: '${widget.productQuantity}',
                    style: const TextStyle(
                      color: green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ), // Color verde para currentProduct?.quantity
                  ),
                ],
              ),
            ),
            const Text("Para continuar, seleccione la novedad",
                style: TextStyle(color: Colors.black, fontSize: 14)),
            const SizedBox(height: 10),
            Card(
              color: Colors.white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  underline: Container(height: 0),
                  selectedItemBuilder: (BuildContext context) {
                    return widget.novedades.map<Widget>((Novedad item) {
                      return Text(item.name ?? '');
                    }).toList();
                  },
                  borderRadius: BorderRadius.circular(10),
                  focusColor: Colors.white,
                  isExpanded: true,
                  isDense: true,
                  hint: const Text(
                    'Seleccionar novedad',
                    style: TextStyle(
                        fontSize: 14,
                        color: black), // Cambia primaryColorApp a tu color
                  ),
                  icon: SizedBox(
                    height: 20,
                    width: 20,
                    child: SvgPicture.asset(
                      color: primaryColorApp,
                      "assets/icons/novedad.svg",
                      height: 20,
                      width: 20,
                      fit: BoxFit.cover,
                    ),
                  ),
                  value: selectedNovedad, // Muestra la opción seleccionada
                  alignment: Alignment.centerLeft,
                  style: const TextStyle(
                      color: black,
                      fontSize: 14), // Cambia primaryColorApp a tu color
                  items: widget.novedades.map((Novedad item) {
                    return DropdownMenuItem<String>(
                      value: item.name,
                      child: Text(item.name ?? ''),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedNovedad =
                          newValue; // Actualiza el estado con la nueva selección
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child:
                  Text('Cancelar', style: TextStyle(color: primaryColorApp))),
          ElevatedButton(
              onPressed: selectedNovedad != null
                  ? () async {
                      // Validamos que tenga una novedad seleccionada
                      if (selectedNovedad != null) {
                        Navigator.pop(context); // Cierra el diálogo
                        await widget.onAccepted(
                            selectedNovedad!); // Llama al callback dinámico
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child:
                  const Text('Aceptar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
