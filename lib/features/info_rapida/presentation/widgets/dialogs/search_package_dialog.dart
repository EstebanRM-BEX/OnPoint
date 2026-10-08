import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/shared/utils/keyboard_watchdog.dart';

/// Pide el nombre del paquete (prefijo PACK). Devuelve el nombre con
/// `Navigator.pop` o null si se cancela.
class SearchPackageDialog extends StatefulWidget {
  const SearchPackageDialog({super.key});

  @override
  State<SearchPackageDialog> createState() => _SearchPackageDialogState();
}

class _SearchPackageDialogState extends State<SearchPackageDialog>
    with WidgetsBindingObserver {
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  // Watchdog: reabre el teclado si el IME del PDA (Zebra/Urovo/Chainway) lo
  // cierra solo mientras el campo conserva el foco.
  late final KeyboardWatchdog _kbWatchdog = KeyboardWatchdog(
    state: this,
    focusNode: _scanFocusNode,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ✅ Inicializar el controlador con la palabra "PACK"
    _scanController.text = 'PACK';
    // ✅ Mover el cursor al final del texto para que el usuario pueda escribir
    _scanController.selection = TextSelection.fromPosition(
      TextPosition(offset: _scanController.text.length),
    );
  }

  @override
  void didChangeMetrics() => _kbWatchdog.onMetricsChanged();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kbWatchdog.dispose();
    _scanFocusNode.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(
        child: Text(
          'BUSCAR PAQUETE',
          textAlign: TextAlign.center,
          style: TextStyle(color: primaryColorApp, fontSize: 20),
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingrese el nombre del paquete para buscarlo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: black, fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextFormField(
              focusNode: _scanFocusNode,
              style: const TextStyle(fontSize: 14, color: Colors.black),
              controller: _scanController,
              // ✅ El cambio crucial: aplicamos el formatter aquí
              inputFormatters: [
                PackageNameFormatter(),
                // Opcional: si solo quieres números después de "PACK", puedes añadir
                // FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
              ],
              decoration: InputDecorations.authInputDecoration(
                hintText: 'Número del paquete',
                labelText: 'Número del paquete',
                suffixIconButton: IconButton(
                  // El botón de limpiar ahora se encarga de dejar solo el prefijo
                  onPressed: () {
                    _scanController.text = 'PACK';
                    _scanController.selection = TextSelection.collapsed(
                      offset: _scanController.text.length,
                    );
                  },
                  icon: Icon(Icons.clear, color: primaryColorApp, size: 20),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().toLowerCase() == 'pack') {
                  return 'Debe ingresar un número de paquete.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: white, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, _scanController.text.toUpperCase());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'BUSCAR',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PackageNameFormatter extends TextInputFormatter {
  final String prefix = 'PACK';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el nuevo valor está vacío, lo reseteamos a "PACK"
    if (newValue.text.isEmpty) {
      return TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }

    // Si el usuario borra texto del prefijo, no permitimos el cambio
    if (!newValue.text.toLowerCase().startsWith(prefix.toLowerCase())) {
      return oldValue;
    }

    // Si el nuevo valor es solo "PACK" y el usuario intenta borrar más, lo dejamos como está
    if (newValue.text.toLowerCase() == prefix.toLowerCase() &&
        oldValue.text.length > prefix.length) {
      return TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }

    // Si el nuevo valor es válido, lo retornamos
    return newValue.copyWith(
      text: newValue.text
          .toUpperCase(), // Opcional: para mantener el prefijo en mayúsculas
    );
  }
}
