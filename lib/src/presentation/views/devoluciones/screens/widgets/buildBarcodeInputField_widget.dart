import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class BuildBarcodeInputField extends StatefulWidget {
  final FocusNode focusNode;
  final Function(String) functionValidate;
  final TextEditingController controller;

  const BuildBarcodeInputField({
    super.key,
    required this.focusNode,
    required this.functionValidate,
    required this.controller,
  });

  @override
  State<BuildBarcodeInputField> createState() => _BuildBarcodeInputFieldState();
}

class _BuildBarcodeInputFieldState extends State<BuildBarcodeInputField> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (value.trim().isNotEmpty) {
        widget.functionValidate(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0,
      child: TextFormField(
        autofocus: true,
        showCursor: false,
        controller: widget.controller,
        keyboardType: TextInputType.none,
        enableInteractiveSelection: false,
        textInputAction: TextInputAction.done,
        style: const TextStyle(color: Colors.transparent),
        focusNode: widget.focusNode,
        onChanged: _onChanged,
        onFieldSubmitted: (value) {
          _debounce?.cancel();
          if (value.trim().isNotEmpty) {
            widget.functionValidate(value);
          }
        },
        decoration: const InputDecoration(
          disabledBorder: InputBorder.none,
          hintStyle: TextStyle(fontSize: 14, color: black),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
