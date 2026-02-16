// ignore_for_file: file_names

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';

class DialogValidateProductSendWidget extends StatelessWidget {
  const DialogValidateProductSendWidget({
    super.key,
    required this.product,
    required this.productExist,
    required this.cantidadController,
  });

  final CountedLine product;
  final CountedLine productExist;
  final TextEditingController cantidadController;

  // Función auxiliar para obtener la cantidad de forma segura
  double _getCantidad(BuildContext context) {
    try {
      if (cantidadController.text.isEmpty) {
        final bloc = context.read<ConteoBloc>();
        // Verificar que quantitySelected no sea null
        return (bloc.quantitySelected ?? 0.0).toDouble();
      } else {
        return double.parse(cantidadController.text);
      }
    } catch (e) {
      print('❌ Error obteniendo cantidad: $e');
      return 0.0;
    }
  }

  // Función segura para cerrar diálogo
  void _safePop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mover la obtención de cantidad dentro del build pero con manejo seguro
    final cantidad = _getCantidad(context);
    final quantityExist = productExist.quantityCounted ?? 0.0;
    final total = quantityExist + cantidad;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  '360 Software Informa',
                  style: TextStyle(color: red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    text: 'Este producto esta registrado con una cantidad de: ',
                    style: TextStyle(
                      color: black,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '($quantityExist) ',
                        style: TextStyle(
                          color: primaryColorApp,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: 'en la ubicación ',
                        style: TextStyle(
                          color: black,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: '${productExist.locationName ?? "N/A"}',
                        style: TextStyle(
                          color: primaryColorApp,
                          fontSize: 14,
                        ),
                      ),
                      if (product.productTracking == "lot") ...[
                        TextSpan(
                          text: ' con lote ',
                          style: TextStyle(
                            color: black,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: '${productExist.lotName ?? "N/A"}.',
                          style: TextStyle(
                            color: primaryColorApp,
                            fontSize: 14,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: RichText(
                  text: TextSpan(
                    text: '¿Desea reemplazar la cantidad registrada por: ',
                    style: TextStyle(
                      color: black,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '($cantidad)',
                        style: TextStyle(
                          color: primaryColorApp,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: '?',
                        style: TextStyle(
                          color: black,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: RichText(
                  text: TextSpan(
                    text: '¿Desea actualizar la cantidad existente ',
                    style: TextStyle(
                      color: black,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '($quantityExist) + ($cantidad) ',
                        style: TextStyle(
                          color: primaryColorApp,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: 'para un total de: ',
                        style: TextStyle(
                          color: black,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: '($total)',
                        style: TextStyle(
                          color: green,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: '?',
                        style: TextStyle(
                          color: black,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Usar el context del callback, no del build
                  final bloc = context.read<ConteoBloc>();
                  bloc.add(UpdateProductConteoEvent(
                    product, 
                    productExist, 
                    cantidad, 
                    true
                  ));
                  // _safePop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  minimumSize: const Size(250, 40),
                ),
                child: Text('REEMPLAZAR', style: TextStyle(color: white)),
              ),
              ElevatedButton(
                onPressed: () {
                  final bloc = context.read<ConteoBloc>();
                  bloc.add(UpdateProductConteoEvent(
                    product, 
                    productExist, 
                    cantidad, 
                    false
                  ));
                  // _safePop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  minimumSize: const Size(250, 40),
                ),
                child: Text('ACTUALIZAR', style: TextStyle(color: white)),
              ),
              ElevatedButton(
                onPressed: () {
                  _safePop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: grey,
                  minimumSize: const Size(250, 40),
                ),
                child: Text('CANCELAR', style: TextStyle(color: white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}