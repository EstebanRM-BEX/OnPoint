// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';

class DialogAdvetenciaCantidadPick extends StatefulWidget {
  const DialogAdvetenciaCantidadPick({
    super.key,
    required this.cantidad,
    required this.currentProduct,
    required this.onAccepted,
    required this.batchId,
  });

  final double cantidad; // Variable para almacenar la cantidad
  final ProductsBatch currentProduct;
  final int batchId; // Variable para almacenar el id del lote
  final VoidCallback onAccepted; // Callback para la acción a ejecutar

  // Variable para almacenar el producto actual

  @override
  State<DialogAdvetenciaCantidadPick> createState() =>
      _DialogAdvetenciaCantidadScreenState();
}

class _DialogAdvetenciaCantidadScreenState
    extends State<DialogAdvetenciaCantidadPick> {
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
                    text: '${widget.currentProduct.quantity}',
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
                    return context
                        .read<BatchBloc>()
                        .novedades
                        .map<Widget>((Novedad item) {
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
                  items:
                      context.read<BatchBloc>().novedades.map((Novedad item) {
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
                        DataBaseSqlite db = DataBaseSqlite();

                        await db.pickProductsRepository.updateNovedad(
                            widget.batchId,
                            widget.currentProduct.idProduct ?? 0,
                            selectedNovedad ?? '',
                            widget.currentProduct.idMove ?? 0);

                        Navigator.pop(context); // Cierra el diálogo
                        widget.onAccepted(); // Llama al callback
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
