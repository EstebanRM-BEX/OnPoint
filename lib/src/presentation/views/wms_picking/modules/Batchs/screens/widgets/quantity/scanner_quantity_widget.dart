import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';

class QuantityScannerWidget extends StatefulWidget {
  final Size size;
  final bool isQuantityOk;
  final bool quantityIsOk;
  final bool locationIsOk;
  final bool productIsOk;
  final bool locationDestIsOk;
  final dynamic totalQuantity;
  final dynamic quantitySelected;
  final String unidades;
  final TextEditingController controller;
  final TextEditingController manualController;
  final FocusNode scannerFocusNode;
  final FocusNode manualFocusNode;
  final bool viewQuantity;
  final VoidCallback onToggleViewQuantity;
  final VoidCallback onValidateButton;
  final VoidCallback onIconButtonPressed;
  final Function(String) onValidateScannerInput;
  final Function(String) onManualQuantityChanged;
  final Function(String) onManualQuantitySubmitted;

  bool isViewCant;

  QuantityScannerWidget({
    super.key,
    required this.size,
    required this.isQuantityOk,
    required this.quantityIsOk,
    required this.locationIsOk,
    required this.productIsOk,
    required this.locationDestIsOk,
    required this.totalQuantity,
    required this.quantitySelected,
    required this.unidades,
    required this.controller,
    required this.manualController,
    required this.scannerFocusNode,
    required this.manualFocusNode,
    required this.viewQuantity,
    required this.onToggleViewQuantity,
    required this.onValidateButton,
    required this.onValidateScannerInput,
    required this.onManualQuantityChanged,
    required this.onManualQuantitySubmitted,
    required this.onIconButtonPressed,
    this.isViewCant = true,
  });

  @override
  State<QuantityScannerWidget> createState() => _QuantityScannerWidgetState();
}

class _QuantityScannerWidgetState extends State<QuantityScannerWidget> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onZebraChanged(String value, BuildContext context) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (value.trim().isNotEmpty) {
        widget.onValidateScannerInput(
          value,
        );
      }
    });
  }

  Color _getColorForDifference(dynamic difference) {
    if (difference == 0) {
      return Colors.transparent; // Ocultar el texto cuando la diferencia es 0
    } else if (difference > 10) {
      // Si la diferencia es mayor a 10
      return Colors.red; // Rojo para una gran diferencia
    } else if (difference > 5) {
      // Si la diferencia es mayor a 5 pero menor o igual a 10
      return Colors.orange; // Naranja para una diferencia moderada
    } else {
      // Si la diferencia es 5 o menos
      return Colors.green; // Verde cuando esté cerca de la cantidad pedida
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamic difference =
        (widget.totalQuantity ?? 0) - widget.quantitySelected;

    return SizedBox(
      width: widget.size.width,
      height: !widget.viewQuantity ? 110 : 150,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Card(
              // color: widget.isQuantityOk
              //     ? widget.quantityIsOk
              //         ? Colors.white
              //         : Colors.grey[300]
              //     : Colors.red[200],
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    if (widget.isViewCant) ...[
                      const Text('Cant:',
                          style: TextStyle(color: black, fontSize: 13)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          (widget.totalQuantity ?? 0.0).toString(),
                          style:
                              TextStyle(color: primaryColorApp, fontSize: 13),
                        ),
                      ),
                      if (difference != 0)
                        const Text('Pdte:',
                            style: TextStyle(color: black, fontSize: 13)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: difference == 0
                            ? const SizedBox()
                            : Text(
                                difference
                                    .clamp(
                                        0,
                                        double
                                            .infinity) // Mantiene que no sea negativo
                                    .toStringAsFixed(2),
                                style: TextStyle(
                                  color: _getColorForDifference(difference),
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ],
                    Text(widget.unidades,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 13)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 5),
                        height: 30,
                        alignment: Alignment.center,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextFormField(
                              showCursor: false,
                              textAlign: TextAlign.center,
                              enabled: widget.locationIsOk &&
                                  widget.productIsOk &&
                                  widget.quantityIsOk &&
                                  !widget.locationDestIsOk,
                              controller: widget.controller,
                              focusNode: widget.scannerFocusNode,
                              keyboardType: TextInputType.none,
                              enableInteractiveSelection: false,
                              style: const TextStyle(color: Colors.transparent),
                              textInputAction: TextInputAction.done,
                              onChanged: (value) {
                                _onZebraChanged(value, context);
                              },
                              onFieldSubmitted: (value) {
                                // Disparo inmediato en Enter: cancela el debounce pendiente
                                _debounce?.cancel();
                                if (value.trim().isNotEmpty) {
                                  widget.onValidateScannerInput(value);
                                }
                                // Limpiar el controller después del submit
                                widget.controller.clear();
                              },
                              decoration: InputDecoration(
                                hintText: widget.quantitySelected.toString(),
                                disabledBorder: InputBorder.none,
                                hintStyle:
                                    const TextStyle(fontSize: 13, color: black),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            )),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          widget.quantityIsOk && widget.quantitySelected >= 0
                              ? widget.onToggleViewQuantity
                              : null,
                      icon: Icon(Icons.edit_note_rounded,
                          color: primaryColorApp, size: 25),
                    )
                  ],
                ),
              ),
            ),
          ),
          if (widget.viewQuantity)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              child: SizedBox(
                height: 35,
                child: TextFormField(
                  focusNode: widget.manualFocusNode,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  controller: widget.manualController,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  onChanged: widget.onManualQuantityChanged,
                  onFieldSubmitted: widget.onManualQuantitySubmitted,
                  decoration: InputDecorations.authInputDecoration(
                    hintText: 'Cantidad',
                    labelText: 'Cantidad',
                    suffixIconButton: IconButton(
                      onPressed: widget.onIconButtonPressed,
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: widget.quantityIsOk && widget.quantitySelected >= 0
                  ? widget.onValidateButton
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                minimumSize: Size(widget.size.width * 0.93, 30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('APLICAR CANTIDAD',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
