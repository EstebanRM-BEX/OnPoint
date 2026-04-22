import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

class DialogUnauthorizedDevice extends StatelessWidget {
  const DialogUnauthorizedDevice({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Center(
            child: Text(
              'Dispositivo no autorizado',
              style: TextStyle(
                  color: primaryColorApp,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          content: const Text(
            'Este dispositivo no está autorizado para usar la aplicación. su suscripción ha expirado o no está activa, por favor contacte con el administrador.',
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: black,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
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
              child: const Text('Aceptar', style: TextStyle(color: white)),
            ),
          ],
        ),
      ),
    );
  }
}
