import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/comprimir_image_utils.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/bloc/wms_packing_bloc.dart';

class DialogCapturaTemperatura extends StatefulWidget {
  final int moveLineId;

  const DialogCapturaTemperatura({super.key, required this.moveLineId});

  @override
  State<DialogCapturaTemperatura> createState() =>
      _DialogCapturaTemperaturaState();
}

class _DialogCapturaTemperaturaState extends State<DialogCapturaTemperatura> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _tomarFoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final originalFile = File(pickedFile.path);
      final compressedFile = await comprimirImagen(originalFile);

      if (compressedFile != null) {
        setState(() {
          _imageFile = compressedFile; // o lo que uses en tu widget
        });
        print('Tamaño final: ${await compressedFile.length()} bytes');
      } else {
        print('No se pudo comprimir la imagen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return BlocConsumer<WmsPackingBloc, WmsPackingState>(
      listener: (context, state) {
        if (state is GetTemperatureFailure) {
          Get.snackbar("360 Software Informa", state.error,
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.red));
        }
      },
      builder: (context, state) {
    final bloc = context.read<WmsPackingBloc>();
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5,
            sigmaY: 5,
          ),
          child: AlertDialog(
            title: const Center(
              child: Text(
                "Captura la temperatura",
                style: TextStyle(fontSize: 16, color: black),
              ),
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_imageFile == null) ...[
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
                      label: const Text('Tomar foto',
                          style: TextStyle(fontSize: 14, color: white)),
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
                        _imageFile!,
                        fit: BoxFit.fill,
                        height: 180,
                        width: 230,
                      ),
                    ),
                    //mostrar el tamaño de la imagen y el formato
                    const SizedBox(height: 5),
                    //tamaño en 5mb
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Tamaño: ${(_imageFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                            style: const TextStyle(fontSize: 10, color: black),
                          ),
                          const Spacer(),
                          Text(
                            'Formato: ${_imageFile!.path.split('.').last.toUpperCase()}',
                            style: const TextStyle(fontSize: 10, color: black),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _tomarFoto,
                            icon: Icon(Icons.refresh, color: primaryColorApp),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _imageFile != null
                                ? () {
                                    context.read<WmsPackingBloc>().add(
                                          GetTemperatureEvent(
                                              file: _imageFile!),
                                        );
                                  }
                                : null,
                            icon: const Icon(Icons.image_search_sharp),
                            label: const Text("Analizar"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTemperatureResult(bloc),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemperatureResult(WmsPackingBloc bloc) {
    return Column(
      children: [
        Card(
          color: white,
          elevation: 2,
          child: ListTile(
            title: RichText(
              text: TextSpan(
                text: 'Temperatura: ',
                style: const TextStyle(color: black, fontSize: 12),
                children: [
                  TextSpan(
                    text: bloc.resultTemperature.temperature == null
                        ? '0.0'
                        : bloc.resultTemperature.temperature.toString() ??
                            '0.0',
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
                RichText(
                  text: TextSpan(
                    text: 'Unidad: ',
                    style: const TextStyle(color: black, fontSize: 12),
                    children: [
                      TextSpan(
                        text: bloc.resultTemperature.unit ?? 'Sin unidad',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: primaryColorApp,
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: 'Origen: ',
                    style: TextStyle(color: primaryColorApp, fontSize: 12),
                    children: [
                      TextSpan(
                        text: bloc.resultTemperature.confidence ?? 'Sin origen',
                        style: const TextStyle(fontSize: 12, color: black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ElevatedButton(
          onPressed:
              _imageFile != null && bloc.resultTemperature.temperature != null
                  ? () {
                      bloc.add(SendTemperatureEvent(
                        file: _imageFile!,
                        moveLineId: widget.moveLineId,
                      ));
                    }
                  : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
            backgroundColor: primaryColorApp,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: const Text("Enviar",
              style: TextStyle(fontSize: 14, color: white)),
        ),
      ],
    );
  }
}
