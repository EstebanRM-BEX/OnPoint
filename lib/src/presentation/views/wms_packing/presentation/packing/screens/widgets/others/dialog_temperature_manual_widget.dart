import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';

import 'package:wms_app/src/presentation/widgets/keyboard_numbers_temp_widget.dart';

class DialogTemperaturaManualPack extends StatefulWidget {
  final int moveLineId;

  const DialogTemperaturaManualPack({super.key, required this.moveLineId});

  @override
  State<DialogTemperaturaManualPack> createState() =>
      _DialogCapturaTemperaturaState();
}

class _DialogCapturaTemperaturaState extends State<DialogTemperaturaManualPack> {
  @override
  Widget build(BuildContext context) {

    return BlocConsumer<PackingPedidoBloc, PackingPedidoState>(
      listener: (context, state) {
        if (state is GetTemperatureFailure) {
          Get.snackbar("360 Software Informa", state.error,
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.red));
        }
      },
      builder: (context, state) {
    final bloc = context.read<PackingPedidoBloc>();

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5,
            sigmaY: 5,
          ),
          child: AlertDialog(
            title: const Center(
              child: Text(
                "Captura la temperatura",
                style: TextStyle(fontSize: 16, color: black),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Debes ingresar la temperatura del producto para continuar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: black),
                  ),
                  const SizedBox(height: 15),
                  //tamaño en 5mb

                  TextFormField(
                    showCursor: false,
                    readOnly: true,
                    controller: bloc.temperatureController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 14,
                      color: black,
                    ),
                    decoration: InputDecorations.authInputDecoration(
                      hintText: 'Temperatura',
                      labelText: 'Temperatura',
                      suffixIconButton: IconButton(
                        onPressed: () {
                          bloc.temperatureController.clear();
                        },
                        icon: Icon(
                          Icons.clear,
                          color: primaryColorApp,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  _buildTemperatureResult(bloc),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemperatureResult(PackingPedidoBloc bloc) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            final text = bloc.temperatureController.text.trim();

            if (text.isEmpty) {
              Get.snackbar(
                "360 Software Informa",
                "Debes ingresar la temperatura",
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: const Icon(Icons.error, color: Colors.red),
              );
              return;
            }

            final RegExp temperaturaRegExp = RegExp(r'^-?\d+(\.\d{1,2})?$');

            if (!temperaturaRegExp.hasMatch(text)) {
              Get.snackbar(
                "360 Software Informa",
                "La temperatura ingresada no tiene un formato válido",
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: const Icon(Icons.warning, color: Colors.orange),
              );
              return;
            }

            // Aquí puedes continuar con el envío si pasa la validación
            bloc.add(
              SendTemperatureManualPackEvent(
                moveLineId: widget.moveLineId,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
            backgroundColor: primaryColorApp,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: const Text("Enviar",
              style: TextStyle(fontSize: 14, color: white)),
        ),
        //mostramos el teclado de temperatura
        const SizedBox(height: 10),
        CustomKeyboardTempNumber(
          controller: bloc.temperatureController,
          isDialog: true,
          onchanged: () {},
        )
      ],
    );
  }
}
