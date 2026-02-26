import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';

class DialogTemperature extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final TextEditingController controller;
  const DialogTemperature({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async => false, // Evita cerrar con botón atrás
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white,
          actionsAlignment: MainAxisAlignment.center,
          title: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thermostat_rounded,
                  size: 50,
                  color: primaryColorApp,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Registrar Temperatura',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecorations.authInputDecoration(
                    labelText: 'Temperatura (°C)',
                    suffixIconButton: IconButton(
                      onPressed: () {
                        //cerramos el dialog
                        //limapiamos el controller
                        controller.clear();
                      },
                      icon: Icon(
                        Icons.clear,
                        color: primaryColorApp,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    //validamos que el campo no este vacio
                    if (controller.text.isEmpty) {
                      Get.snackbar("360 Software Informa", 'Campo vacio',
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.white,
                          colorText: primaryColorApp,
                          icon: Icon(Icons.error, color: Colors.red));
                      return;
                    }

                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColorApp,
                    minimumSize: Size(size.width * 0.8, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Confirmar',
                      style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    //cerramos el dialog
                    //limpiamos el controller

                    controller.clear();
                    onCancel();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: grey,
                    minimumSize: Size(size.width * 0.8, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
