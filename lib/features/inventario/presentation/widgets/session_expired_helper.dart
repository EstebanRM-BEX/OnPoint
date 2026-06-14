// lib/features/inventario/presentation/widgets/session_expired_helper.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';

class SessionExpiredHelper {
  static void showDialog() {
    Get.defaultDialog(
      title: 'Alerta',
      titleStyle: const TextStyle(color: Colors.red, fontSize: 18),
      middleText: 'Sesion expirada, por favor inicie sesión nuevamente',
      middleTextStyle: TextStyle(color: black, fontSize: 14),
      backgroundColor: Colors.white,
      radius: 10,
      actions: [
        ElevatedButton(
          onPressed: () {
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColorApp,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text('Aceptar', style: TextStyle(color: white)),
        ),
      ],
    );
  }
}
