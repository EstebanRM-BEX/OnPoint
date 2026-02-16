// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/models/novedades_response_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_photo_novedad_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';

class DialogPackAdvetenciaCantidadScreen extends StatefulWidget {
  const DialogPackAdvetenciaCantidadScreen({
    super.key,
    required this.cantidad,
    required this.currentProduct,
    required this.onAccepted,
    required this.onSplit,
  });

  final double cantidad; // Variable para almacenar la cantidad
  final ProductoPedido currentProduct;
  final VoidCallback onAccepted; // Callback para la acción a ejecutar
  final VoidCallback onSplit; // Callback para la acción a split

  // Variable para almacenar el producto actual

  @override
  State<DialogPackAdvetenciaCantidadScreen> createState() =>
      _DialogAdvetenciaCantidadScreenState();
}

class _DialogAdvetenciaCantidadScreenState
    extends State<DialogPackAdvetenciaCantidadScreen> {
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
            const Text(
                "Para continuar, seleccione la novedad o divida la cantidad del producto",
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
                        .read<PackingPedidoBloc>()
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
                      .read<PackingPedidoBloc>()
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
              visible: widget.cantidad >= 1,
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
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(size.width * 0.3, 30),
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
                      showDialog(
                        context: context,
                        builder: (_) {
                          return DialogCapturaNovedad(
                            onResult: (File? file) async {
                              if (file != null) {
                                context.read<PackingPedidoBloc>().add(
                                      SendImageNovedad(
                                        cantidad: widget.cantidad,
                                        file: file,
                                        moveLineId:
                                            widget.currentProduct.idMove ?? 0,
                                        pedidoId:
                                            widget.currentProduct.pedidoId ?? 0,
                                        productId:
                                            widget.currentProduct.idProduct ??
                                                0,
                                      ),
                                    );
                                final db = DataBaseSqlite();
                                await db.productosPedidosRepository
                                    .updateNovedadPacking(
                                        widget.currentProduct.pedidoId ?? 0,
                                        widget.currentProduct.idProduct ?? 0,
                                        selectedNovedad ?? '',
                                        'packing-pack');
                                // Cierra el diálogo y ejecuta el callback después de actualizar
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              } else {
                                if (selectedNovedad != null) {
                                  final db = DataBaseSqlite();

                                  await db.productosPedidosRepository
                                      .updateNovedadPacking(
                                          widget.currentProduct.pedidoId ?? 0,
                                          widget.currentProduct.idProduct ?? 0,
                                          selectedNovedad ?? '',
                                          'packing-pack');
                                  // Cierra el diálogo y ejecuta el callback después de actualizar
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                  widget.onAccepted();
                                }
                              }
                            },
                          );
                        },
                      );
                    }
                  : null,
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
