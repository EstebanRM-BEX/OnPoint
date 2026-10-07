import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/comprimir_image_utils.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/scan/packing_scan_bloc.dart';

/// Registro de temperatura tras separar un producto que la maneja, con el
/// diseño del módulo anterior: con `showPhotoTemperature` se toma la foto,
/// se analiza con IA y se envía; si no, se digita. No se puede cerrar sin
/// enviarla; la pantalla de escaneo lo cierra cuando el envío termina bien.
Future<void> showTemperaturaPackDialog(
  BuildContext context,
  PackingScanBloc bloc,
) {
  final conFoto = bloc.state.config.showPhotoTemperature;
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: PopScope(
        canPop: false,
        child: conFoto
            ? const _TemperaturaFotoDialog()
            : const _TemperaturaManualDialog(),
      ),
    ),
  );
}

class _TemperaturaFotoDialog extends StatefulWidget {
  const _TemperaturaFotoDialog();

  @override
  State<_TemperaturaFotoDialog> createState() => _TemperaturaFotoDialogState();
}

class _TemperaturaFotoDialogState extends State<_TemperaturaFotoDialog> {
  File? _foto;

  Future<void> _tomarFoto() async {
    final tomada = await ImagePicker().pickImage(source: ImageSource.camera);
    if (tomada == null) return;
    final comprimida = await comprimirImagen(File(tomada.path));
    if (comprimida == null || !mounted) return;
    setState(() => _foto = comprimida);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackingScanBloc, PackingScanState>(
      builder: (context, s) {
        final bloc = context.read<PackingScanBloc>();
        final foto = _foto;
        // La lectura solo vale si corresponde a la foto actual.
        final lectura = s.imagenTemperatura == foto?.path
            ? s.temperaturaIa
            : null;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            contentPadding: const EdgeInsets.all(5),
            title: const Center(
              child: Text(
                'Captura la temperatura',
                style: TextStyle(fontSize: 16, color: black),
              ),
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (foto == null) ...[
                    const Icon(Icons.camera_alt, size: 60, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      'Debes tomar una foto para capturar la temperatura',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: black),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _tomarFoto,
                      icon: const Icon(Icons.camera, color: white),
                      label: const Text(
                        'Tomar foto',
                        style: TextStyle(fontSize: 14, color: white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorApp,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.file(
                        foto,
                        fit: BoxFit.fill,
                        height: 180,
                        width: 230,
                        cacheWidth: 460,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Text(
                            'Tamaño: ${(foto.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                            style: const TextStyle(fontSize: 10, color: black),
                          ),
                          const Spacer(),
                          Text(
                            'Formato: ${foto.path.split('.').last.toUpperCase()}',
                            style: const TextStyle(fontSize: 10, color: black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _tomarFoto,
                            icon: Icon(Icons.refresh, color: primaryColorApp),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () =>
                                bloc.add(TemperaturaPackLeida(foto.path)),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(100, 30),
                              backgroundColor: primaryColorApp,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            child: const Text(
                              'Analizar',
                              style: TextStyle(fontSize: 12, color: white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Card(
                        color: white,
                        elevation: 2,
                        child: ListTile(
                          title: Text.rich(
                            TextSpan(
                              text: 'Temperatura: ',
                              style: const TextStyle(
                                color: black,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: '${lectura?.temperature ?? 0.0}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: primaryColorApp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Unidad: ',
                                  style: const TextStyle(
                                    color: black,
                                    fontSize: 10,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: (lectura?.unit.isNotEmpty ?? false)
                                          ? lectura!.unit
                                          : 'Sin unidad',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: primaryColorApp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  text: 'Origen: ',
                                  style: TextStyle(
                                    color: primaryColorApp,
                                    fontSize: 10,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          (lectura?.confidence.isNotEmpty ??
                                              false)
                                          ? lectura!.confidence
                                          : 'Sin origen',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ElevatedButton(
                        onPressed: lectura?.temperature == null
                            ? null
                            : () => bloc.add(
                                TemperaturaPackEnviada(
                                  lectura!.temperature!,
                                  imagePath: foto.path,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 30),
                          backgroundColor: primaryColorApp,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: const Text(
                          'Enviar',
                          style: TextStyle(fontSize: 14, color: white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TemperaturaManualDialog extends StatefulWidget {
  const _TemperaturaManualDialog();

  @override
  State<_TemperaturaManualDialog> createState() =>
      _TemperaturaManualDialogState();
}

class _TemperaturaManualDialogState extends State<_TemperaturaManualDialog> {
  final _controller = TextEditingController();
  String? _aviso;

  static final _formato = RegExp(r'^-?\d+(\.\d{1,2})?$');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _controller.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) {
      setState(() => _aviso = 'Debes ingresar la temperatura');
      return;
    }
    if (!_formato.hasMatch(texto)) {
      setState(
        () => _aviso = 'La temperatura ingresada no tiene un formato válido',
      );
      return;
    }
    setState(() => _aviso = null);
    context.read<PackingScanBloc>().add(
      TemperaturaPackEnviada(double.parse(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        title: const Center(
          child: Text(
            'Captura la temperatura',
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
              TextFormField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                style: const TextStyle(fontSize: 14, color: black),
                decoration: InputDecorations.authInputDecoration(
                  hintText: 'Temperatura',
                  labelText: 'Temperatura',
                  suffixIconButton: IconButton(
                    onPressed: _controller.clear,
                    icon: Icon(Icons.clear, color: primaryColorApp, size: 20),
                  ),
                ),
              ),
              if (_aviso != null) ...[
                const SizedBox(height: 6),
                Text(_aviso!, style: const TextStyle(color: red, fontSize: 12)),
              ],
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: _enviar,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  'Enviar',
                  style: TextStyle(fontSize: 14, color: white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
