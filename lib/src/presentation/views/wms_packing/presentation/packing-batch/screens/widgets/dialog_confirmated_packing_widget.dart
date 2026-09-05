import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/features/packaging_types/domain/entities/packaging_type.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_bloc.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_event.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_state.dart';
import 'package:wms_app/shared/utils/keyboard_watchdog.dart';

class DialogConfirmatedPacking extends StatefulWidget {
  const DialogConfirmatedPacking({
    super.key,
    required this.productos,
    required this.isCertificate,
    required this.isSticker,
    required this.onToggleSticker,
    required this.onConfirm,
    required this.manejaPeso,
    required this.manejaTipoEmpaque,
  });

  final List<ProductoPedido> productos;
  final bool isCertificate;
  final bool isSticker;
  final bool manejaPeso;
  final bool manejaTipoEmpaque;
  final void Function(bool newValue) onToggleSticker;
  final void Function(PackagingType? type, String weight) onConfirm;

  @override
  State<DialogConfirmatedPacking> createState() =>
      _DialogConfirmatedPackingState();
}

class _DialogConfirmatedPackingState extends State<DialogConfirmatedPacking>
    with WidgetsBindingObserver {
  late bool localSticker; // Estado interno del checkbox

  final TextEditingController _weightController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();
  PackagingType? _selectedPackagingType;

  // Evita que un doble-toque (común en algunos dispositivos) dispare
  // onConfirm más de una vez antes de que Navigator.pop cierre el diálogo,
  // lo que duplicaba el paquete y el mensaje "Empaquetado exitoso".
  bool _isConfirming = false;

  // Watchdog: reabre el teclado si el IME del PDA (Zebra/Urovo/Chainway) lo
  // cierra solo mientras el campo de peso conserva el foco.
  late final KeyboardWatchdog _kbWatchdog = KeyboardWatchdog(
    state: this,
    focusNode: _weightFocusNode,
  );

  @override
  void initState() {
    super.initState();
    localSticker = widget.isSticker; // inicializamos con el valor que nos pasan
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => _kbWatchdog.onMetricsChanged();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kbWatchdog.dispose();
    _weightController.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<PackagingTypeBloc>()..add(GetLocalPackagingTypesEvent()),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white,
          actionsAlignment: MainAxisAlignment.center,
          title: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    '¿Está seguro de empacar los productos seleccionados?',
                    style: TextStyle(color: primaryColorApp, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Total de productos: ${widget.productos.length}',
                    style: const TextStyle(color: black, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // const Text(
                //   'Incluir sticker de certificación',
                //   style: TextStyle(color: black, fontSize: 14),
                // ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Checkbox(
                //       value: localSticker,
                //       onChanged: (value) {
                //         if (value != null) {
                //           setState(() {
                //             localSticker = value;
                //           });
                //           widget.onToggleSticker(value);
                //         }
                //       },
                //     ),
                //     Icon(Icons.print, color: primaryColorApp),
                //   ],
                // ),
                if (!widget.isCertificate)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      "Está realizando una separación sin certificado, tampoco se incluirá el sticker de certificación.",
                      style: TextStyle(color: black, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (widget.manejaTipoEmpaque)
                  BlocBuilder<PackagingTypeBloc, PackagingTypeState>(
                    builder: (context, state) {
                      if (state is PackagingTypesLoadInProgress) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is PackagingTypesLoadSuccess) {
                        return SizedBox(
                          child: DropdownButtonFormField<PackagingType>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Tipo de Empaque *',
                              labelStyle: const TextStyle(
                                color: black,
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            value: _selectedPackagingType,
                            items: state.packagingTypes.map((
                              PackagingType type,
                            ) {
                              return DropdownMenuItem<PackagingType>(
                                value: type,
                                child: Text(
                                  type.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: black, fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (PackagingType? newValue) {
                              setState(() {
                                _selectedPackagingType = newValue;
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Seleccione un tipo' : null,
                          ),
                        );
                      } else if (state is PackagingTypeLoadFailure) {
                        return Center(
                          child: Text(
                            'Error al cargar tipos: ${state.message}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                const SizedBox(height: 10),
                if (widget.manejaPeso)
                  TextFormField(
                    controller: _weightController,
                    focusNode: _weightFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(color: black, fontSize: 12),
                      labelText: 'Peso (kg) *',
                      labelStyle: TextStyle(color: black, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese el peso';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingrese un número válido';
                      }
                      return null;
                    },
                  ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_isConfirming) return;

                //validamos que se haya seleccionado un tipo de empaque
                if (_selectedPackagingType == null &&
                    widget.manejaTipoEmpaque) {
                  Get.snackbar(
                    "360 Software Informa",
                    "Por favor seleccione un tipo de empaque",
                    backgroundColor: white,
                    colorText: primaryColorApp,
                    icon: Icon(Icons.error, color: Colors.amber),
                  );
                  return;
                }

                //validamos que se haya seleccionado un peso
                if (_weightController.text.isEmpty && widget.manejaPeso) {
                  Get.snackbar(
                    "360 Software Informa",
                    "Por favor seleccione un peso",
                    backgroundColor: white,
                    colorText: primaryColorApp,
                    icon: Icon(Icons.error, color: Colors.amber),
                  );
                  return;
                }

                //si todo esta bien, llamamos a la funcion onConfirm
                _isConfirming = true;
                widget.onConfirm(
                  _selectedPackagingType,
                  _weightController.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
