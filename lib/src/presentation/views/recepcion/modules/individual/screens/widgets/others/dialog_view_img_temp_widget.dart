import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/api/api_request_service.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

Future<void> showImageDialog(
  BuildContext context,
  String imageUrl,
) async {
  // El API view_imagen_product devuelve una URL con el path /api/view_imagen_product/{id}
  // que responde HTML en lugar de la imagen real. Se convierte al endpoint
  // estándar de Odoo /web/image que sí autentica correctamente con la cookie.
  final resolvedUrl = _resolveOdooImageUrl(imageUrl);

  Get.dialog(
    const DialogLoading(message: 'Cargando imagen...'),
    barrierDismissible: false,
  );

  final imageBytes = await ApiRequestService().fetchImageBytesFromProtectedUrl(
    fullImageUrl: resolvedUrl,
    isLoadinDialog: false,
  );

  Get.back(); // cerrar el loading

  if (imageBytes == null) {
    Get.snackbar(
      'Error',
      'No se pudo cargar la imagen',
      backgroundColor: white,
      colorText: primaryColorApp,
      icon: const Icon(Icons.error, color: Colors.red),
    );
    return;
  }

  if (!context.mounted) return;

  final isSvg = _isSvgBytes(imageBytes);

  showDialog(
    context: context,
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: isSvg
                        ? SvgPicture.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                            placeholderBuilder: (_) => const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        : Image.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 200,
                              child: Center(
                                child: Icon(Icons.broken_image,
                                    size: 60, color: Colors.grey),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cerrar',
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

/// Convierte la URL del endpoint personalizado al endpoint estándar de Odoo.
/// http://host/api/view_imagen_product/2511
/// → https://host/web/image/product.product/2511/image_1024
String _resolveOdooImageUrl(String url) {
  final match = RegExp(r'view_imagen_product/(\d+)').firstMatch(url);
  if (match != null) {
    final id = match.group(1);
    final uri = Uri.tryParse(url);
    if (uri != null) {
      return 'https://${uri.host}/web/image/product.product/$id/image_1024';
    }
  }
  return url;
}

bool _isSvgBytes(Uint8List bytes) {
  final header = String.fromCharCodes(bytes.take(200));
  return header.contains('<svg') || header.contains('<?xml');
}
