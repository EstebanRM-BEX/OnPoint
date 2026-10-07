import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/scan/packing_scan_bloc.dart';

/// Registro de temperatura tras separar un producto que la maneja. Con
/// `showPhotoTemperature` se toma la foto del termómetro y la IA propone el
/// valor; si no, se digita. No se puede cerrar sin enviarla.
Future<void> showTemperaturaPackDialog(
  BuildContext context,
  PackingScanBloc bloc,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: const PopScope(canPop: false, child: _TemperaturaPackDialog()),
    ),
  );
}

class _TemperaturaPackDialog extends StatefulWidget {
  const _TemperaturaPackDialog();

  @override
  State<_TemperaturaPackDialog> createState() => _TemperaturaPackDialogState();
}

class _TemperaturaPackDialogState extends State<_TemperaturaPackDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _foto() async {
    final foto = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (foto == null || !mounted) return;
    context.read<PackingScanBloc>().add(TemperaturaPackLeida(foto.path));
  }

  void _enviar(String? imagePath) {
    final valor = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (valor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese una temperatura válida')),
      );
      return;
    }
    context.read<PackingScanBloc>().add(
      TemperaturaPackEnviada(valor, imagePath: imagePath),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PackingScanBloc, PackingScanState>(
      listenWhen: (a, b) =>
          a.temperaturaIa != b.temperaturaIa ||
          a.requiereTemperatura != b.requiereTemperatura,
      listener: (context, s) {
        final t = s.temperaturaIa?.temperature;
        if (t != null && _controller.text.isEmpty) {
          _controller.text = t.toString();
        }
        if (!s.requiereTemperatura) Navigator.of(context).pop();
      },
      builder: (context, s) {
        final conFoto = s.config.showPhotoTemperature;
        final imagen = s.imagenTemperatura;
        return AlertDialog(
          backgroundColor: white,
          title: Text(
            'Temperatura del producto',
            textAlign: TextAlign.center,
            style: TextStyle(color: primaryColorApp, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.producto?.productName ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (conFoto)
                OutlinedButton.icon(
                  onPressed: _foto,
                  icon: Icon(
                    imagen == null ? Icons.photo_camera : Icons.check_circle,
                    color: imagen == null ? primaryColorApp : green,
                  ),
                  label: Text(
                    imagen == null
                        ? 'Tomar foto del termómetro'
                        : 'Repetir foto',
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Temperatura',
                  suffixText: s.temperaturaIa?.unit ?? '°',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: conFoto && imagen == null
                  ? null
                  : () => _enviar(imagen),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text('Enviar', style: TextStyle(color: white)),
            ),
          ],
        );
      },
    );
  }
}
