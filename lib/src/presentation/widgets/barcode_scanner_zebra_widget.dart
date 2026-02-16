import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class BarcodeScannerField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String, BuildContext) onBarcodeScanned;
  final Function(String, String, BuildContext) onKeyScanned;
  final String scannedValue5;

  const BarcodeScannerField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onBarcodeScanned,
    required this.onKeyScanned,
    required this.scannedValue5,
  });

  @override
  Widget build(BuildContext context) {
    return _buildScanInput(context);
  }

  Widget _buildScanInput(BuildContext context) {
    return Container(
      height: 15,
      margin: const EdgeInsets.only(bottom: 5),
      child: TextFormField(
        keyboardType: TextInputType.none,
        showCursor: false,
        autofocus: true,
        textInputAction: TextInputAction.done,
        controller: controller,
        focusNode: focusNode,
        onFieldSubmitted: (value) {
          onBarcodeScanned(value, context);
        },
        style: const TextStyle(color: Colors.transparent),
        decoration: const InputDecoration(
          disabledBorder: InputBorder.none,
          hintStyle: TextStyle(fontSize: 14, color: black),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
