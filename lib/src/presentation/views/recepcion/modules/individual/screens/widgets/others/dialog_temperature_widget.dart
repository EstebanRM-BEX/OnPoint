import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/comprimir_image_utils.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';

class DialogCapturaTemperatura extends StatefulWidget {
  final int moveLineId;

  const DialogCapturaTemperatura({super.key, required this.moveLineId});

  @override
  State<DialogCapturaTemperatura> createState() =>
      _DialogCapturaTemperaturaState();
}

class _DialogCapturaTemperaturaState extends State<DialogCapturaTemperatura> {
    final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _preguntando = true;
  bool _cargandoFoto = false;
  
  // 1. NUEVA VARIABLE SEMÁFORO
  bool _isPicking = false; 

  Future<void> _tomarFoto() async {
    // 2. BLOQUEO TEMPRANO: Si ya está activo, salimos inmediatamente.
    if (_isPicking) return;
    
    _isPicking = true; // 🔴 Bloqueamos

    setState(() {
      _cargandoFoto = true;
    });

    try {
      // 3. LLAMADA PROTEGIDA
      // Agregamos imageQuality para optimizar memoria (opcional pero recomendado)
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 50
      );
      
      if (mounted) {
        if (pickedFile != null) {
          setState(() {
            _imageFile = File(pickedFile.path);
            _cargandoFoto = false;
            _preguntando = false;
          });
        } else {
          // El usuario canceló la cámara
          setState(() {
            _cargandoFoto = false;
          });
        }
      }
    } catch (e) {
      // 4. CAPTURA DEL ERROR ESPECÍFICO
      if (e.toString().contains('already_active')) {
        debugPrint('Ignorando llamada duplicada a la cámara');
      } else {
        debugPrint('Error al tomar foto: $e');
        if(mounted) {
           setState(() => _cargandoFoto = false);
        }
      }
    } finally {
      // 5. LIBERACIÓN DEL SEMÁFORO
      _isPicking = false; // 🟢 Desbloqueamos
    }
  }

  @override
  Widget build(BuildContext context) {

    return BlocConsumer<RecepcionBloc, RecepcionState>(
      listener: (context, state) {
        if (state is GetTemperatureFailure) {
          Get.snackbar("360 Software Informa", state.error,
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.red));
        }
      },
      builder: (context, state) {
        final bloc = context.read<RecepcionBloc>();
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
                          ElevatedButton(
                            onPressed: _imageFile != null
                                ? () {
                                    context.read<RecepcionBloc>().add(
                                          GetTemperatureEvent(
                                              file: _imageFile!),
                                        );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              // en lugar de minimumSize
                              minimumSize: const Size(100, 30),
                              backgroundColor: primaryColorApp,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            child: const Text("Analizar",
                                style: TextStyle(fontSize: 12, color: white)),
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

  Widget _buildTemperatureResult(RecepcionBloc bloc) {
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
                        : bloc.resultTemperature.temperature.toString(),
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
