import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

Future<void> showImageDialog(
  BuildContext context,
  String imageUrl,
) async {
  // Mostrar un loading mientras se descarga la imagen
  Get.dialog(
    const DialogLoading(message: 'Cargando imagen...'),
    barrierDismissible: false,
  );

  final imageBytes = await ApiRequestService().fetchImageBytesFromProtectedUrl(
    fullImageUrl: imageUrl,
    isLoadinDialog: false, // ya lo manejamos manualmente
  );

  Get.back(); // cerrar el loading

  if (imageBytes == null) {
    //cerramos el loading y mostramos un error
    if(!context.mounted) return;
    Navigator.pop(context);
    Get.snackbar(
      'Error',
      'No se pudo cargar la imagen',
      backgroundColor: white,
      colorText: primaryColorApp,
      icon: const Icon(Icons.error, color: Colors.red),
    );
    return;
  }

  // Mostrar el diálogo con la imagen cargada
  showDialog(
    // ignore: use_build_context_synchronously
    context: context,
    builder: (context) {
      return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5,
            sigmaY: 5,
          ),
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FutureBuilder(
                    future: Future.delayed(const Duration(milliseconds: 100)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
        
                      return InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 3.0,
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cerrar",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
