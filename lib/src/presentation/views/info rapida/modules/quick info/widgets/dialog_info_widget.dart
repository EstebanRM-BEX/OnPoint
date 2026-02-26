// ignore_for_file: file_names

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';

class DialogInfoQuick extends StatelessWidget {
  final BuildContext contextScreen;

  const DialogInfoQuick({super.key, required this.contextScreen});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'INFORMACIÓN RÁPIDA',
              textAlign: TextAlign.center,
              style: TextStyle(color: primaryColorApp, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              'Seleccione una de las siguientes opciones para realizar la búsqueda manual',
              textAlign: TextAlign.center,
              style: TextStyle(color: black, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Opción 1: PRODUCTOS
            OptionCard(
              label: 'PRODUCTOS',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, 'list-product');
              },
            ),

            // Opción 2: UBICACIONES
            OptionCard(
              label: 'UBICACIONES',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, 'list-location');
              },
            ),
            OptionCard(
              label: 'PAQUETES',
              onTap: () {
                Navigator.pop(context);
                //DIALOGO PARA INGREGSAR EL NOMBRE DEL PAQUETE Y BUSCARLO
                // Inmediatamente después, se abre el nuevo diálogo
                showPackageNameDialog(contextScreen);
              },
            ),
          ],
        ),
      ),
    );
  }
}

void showPackageNameDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SearchPackageDialog(),
  );
}

class SearchPackageDialog extends StatefulWidget {
  const SearchPackageDialog({super.key});

  @override
  State<SearchPackageDialog> createState() => _SearchPackageDialogState();
}

class _SearchPackageDialogState extends State<SearchPackageDialog> {
  final TextEditingController _scanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // ✅ Inicializar el controlador con la palabra "PACK"
    _scanController.text = 'PACK';
    // ✅ Mover el cursor al final del texto para que el usuario pueda escribir
    _scanController.selection = TextSelection.fromPosition(
      TextPosition(offset: _scanController.text.length),
    );
  }

  @override
  void dispose() {
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
                        offset: _scanController.text.length);
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
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('CANCELAR',
                    style: TextStyle(color: white, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<InfoRapidaBloc>().add(GetInfoRapida(
                        _scanController.text.toUpperCase(),
                        false,
                        false,
                        false));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('BUSCAR',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        )
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

class OptionCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: primaryColorApp,
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        title: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
