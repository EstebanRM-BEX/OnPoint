import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';

class SegundaUnidadInputWidget extends StatelessWidget {
  const SegundaUnidadInputWidget({
    super.key,
    required this.controller,
    required this.uomLabel,
    this.focusNode,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String uomLabel;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Card(
        elevation: 3,
        color: enabled ? null : Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.scale_outlined,
                size: 18,
                color:  primaryColorApp,
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Text( 
                    "2da unidad:  ",
                    style: TextStyle(
                      color:  black ,
                    ),
                  ),
                  Text(
                    uomLabel,
                    style: TextStyle(
                      color: primaryColorApp,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: 'Ingrese cantidad' ,
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                    suffixStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: enabled ? primaryColorApp : Colors.grey,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: primaryColorApp,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: enabled ? black : Colors.grey,
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
