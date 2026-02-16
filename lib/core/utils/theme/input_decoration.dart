import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class InputDecorations {
  static InputDecoration authInputDecoration({
    String? hintText,
    required String labelText,
    IconData? prefixIcon,
    IconButton? suffixIconButton,
  }) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      fillColor: Colors.white.withOpacity(0.1),
      filled: true,
      enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: grey)),
      focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primaryColorApp)),
      border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primaryColorApp)),
      hintText: hintText,
      labelText: labelText,
      labelStyle: const TextStyle(color: grey, fontSize: 14),
      hintStyle: const TextStyle(color: grey, fontSize: 14),
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: primaryColorApp) : null,
      suffixIcon: suffixIconButton,
    );
  }
}
