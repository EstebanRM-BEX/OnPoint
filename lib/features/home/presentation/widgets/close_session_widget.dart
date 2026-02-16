// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/injection_container.dart';

class CloseSession extends StatelessWidget {
  const CloseSession({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: white,
        title: Center(
            child: Text('Cerrar sesión',
                style: TextStyle(color: primaryColorApp))),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 40),
              backgroundColor: grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: white,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 40),
              backgroundColor: primaryColorApp,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              // Mostrar el diálogo de carga
              showDialog(
                context: context,
                barrierDismissible:
                    false, // No permitir que el usuario cierre el diálogo manualmente
                builder: (context) => const DialogLoading(
                  message: 'Cerrando sesión...',
                ),
              );

              PrefUtils.clearPrefs();
              getIt<IStorageService>().removeUrlWebsite();
              await DataBaseSqlite().deleteBDCloseSession();
              await Future.delayed(const Duration(seconds: 1));
              PrefUtils.setIsLoggedIn(false);

              // Cerrar el diálogo de carga
              Navigator.pop(context);

              // Navegar a la pantalla de inicio
              Navigator.pushNamedAndRemoveUntil(
                context,
                'enterprice',
                (route) => false,
              );
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(
                color: white,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
