import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wms_app/src/core/constans/colors.dart';

class DialogCapturaNovedad extends StatefulWidget {
  final void Function(File? file) onResult;

  const DialogCapturaNovedad({super.key, required this.onResult});

  @override
  State<DialogCapturaNovedad> createState() => _DialogCapturaNovedadState();
}
class _DialogCapturaNovedadState extends State<DialogCapturaNovedad> {
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        title: const Center(
          child: Text("Foto de novedad", style: TextStyle(fontSize: 16, color: black)),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _preguntando
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.help_outline, size: 60, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      '¿Deseas tomar una foto como evidencia de la novedad?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: black),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onResult(null);
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            child: const Text('No', style: TextStyle(color: black)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _tomarFoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColorApp,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            child: const Text('Sí', style: TextStyle(color: white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : _cargandoFoto
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.fill,
                            height: 300,
                            width: 250,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _tomarFoto,
                          icon: const Icon(Icons.refresh, color: white),
                          label: const Text('Repetir foto', style: TextStyle(color: white)),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(250, 40),
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            widget.onResult(_imageFile);
                            Get.back();
                          },
                          icon: const Icon(Icons.send, color: white),
                          label: const Text('Enviar imagen', style: TextStyle(color: white)),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(250, 40),
                            backgroundColor: primaryColorApp,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
