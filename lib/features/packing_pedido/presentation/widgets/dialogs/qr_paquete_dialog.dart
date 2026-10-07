import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';

/// QR con la URL de información del paquete en Odoo
/// (`<empresa>/package/info/<nombre>`), igual que el módulo anterior.
Future<void> showQrPaqueteDialog(BuildContext context, String nombre) async {
  final url = '${await PrefUtils.getEnterprise()}/package/info/$nombre';
  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      title: Center(
        child: Text(
          'Información del paquete',
          style: TextStyle(color: primaryColorApp, fontSize: 16),
        ),
      ),
      content: SizedBox(
        height: 200,
        width: 200,
        child: QrImageView(data: url, version: QrVersions.auto, size: 200),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Cerrar', style: TextStyle(color: white)),
        ),
      ],
    ),
  );
}
