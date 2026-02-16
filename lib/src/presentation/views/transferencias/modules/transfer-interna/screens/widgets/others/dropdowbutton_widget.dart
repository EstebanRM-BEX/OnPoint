// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/sounds_utils.dart';
import 'package:wms_app/core/utils/vibrate_utils.dart';
import 'package:wms_app/src/presentation/models/novedades_response_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/response_transferencias.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/bloc/transferencia_bloc.dart';

class DialogTransferAdvetenciaCantidadScreen extends StatefulWidget {
  const DialogTransferAdvetenciaCantidadScreen({
    super.key,
    required this.cantidad,
    required this.currentProduct,
    required this.onAccepted,
    required this.onSplit,
  });

  final dynamic cantidad; // Variable para almacenar la cantidad
  final LineasTransferenciaTrans currentProduct;
  final VoidCallback onAccepted; // Callback para la acción a ejecutar
  final VoidCallback onSplit; // Callback para la acción a split

  // Variable para almacenar el producto actual

  @override
  State<DialogTransferAdvetenciaCantidadScreen> createState() =>
      _DialogAdvetenciaCantidadScreenState();
}

class _DialogAdvetenciaCantidadScreenState
    extends State<DialogTransferAdvetenciaCantidadScreen> {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();

  String? selectedNovedad; // Variable para almacenar la opción seleccionada

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: Colors.white,
        title: const Center(
            child: Text('360 Software Informa',
                textAlign: TextAlign.center,
                style: TextStyle(color: yellow, fontSize: 18))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'La cantidad recibida ',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 12), // Color del texto normal
                  ),
                  TextSpan(
                    text: '${widget.cantidad} ',
                    style: TextStyle(
                      color: primaryColorApp,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    // Color rojo para quantity
                  ),
                  const TextSpan(
                    text: 'es menor a la cantidad de la transferencia ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ), // Color del texto normal
                  ),
                  TextSpan(
                    text:
                        (widget.currentProduct.cantidadFaltante ?? 0.0).toString(),
                    style: const TextStyle(
                      color: green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ), // Color verde para currentProduct?.quantity
                  ),
                ],
              ),
            ),
            const Text(
                "Para continuar, seleccione la novedad o divida la cantidad del producto",
                // "Para continuar, seleccione la novedad  del producto",
                style: TextStyle(color: Colors.black, fontSize: 12)),
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
                        .read<TransferenciaBloc>()
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
                  items: context
                      .read<TransferenciaBloc>()
                      .novedades
                      .map((Novedad item) {
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
            Visibility(
              visible: (widget.currentProduct.quantityOrdered > 1),
              child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Cierra el diálogo
                    widget.onSplit(); // L
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: grey,
                    minimumSize: Size(size.width * 0.6, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: const Text('Dividir Cantidad',
                      style: TextStyle(color: Colors.white))),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              context.read<TransferenciaBloc>().add(
                    CleanFieldsEvent(),
                  );
              Navigator.pop(context); // Cierra el diálogo
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              minimumSize: Size(size.width * 0.3, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
              onPressed: () async {
                // Validamos que tenga una novedad seleccionada
                if (selectedNovedad != null) {
                  DataBaseSqlite db = DataBaseSqlite();
                  await db.productTransferenciaRepository.updateNovedadTransfer(
                      widget.currentProduct.idTransferencia ?? 0,
                      int.parse(widget.currentProduct.productId),
                      widget.currentProduct.idMove ?? 0,
                      selectedNovedad ?? '');
                  Navigator.pop(context); // Cierra el diálogo
                  widget.onAccepted(); // Llama al callback
                } else {
                  _audioService.playErrorSound();
                  _vibrationService.vibrate();
                  Get.snackbar("360 Software Informa",
                      'Seleccione una novedad, para continuar',
                      backgroundColor: white,
                      colorText: primaryColorApp,
                      icon: Icon(Icons.error, color: Colors.amber));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                minimumSize: Size(size.width * 0.3, 30),
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
