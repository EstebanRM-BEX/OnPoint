import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Mensaje de lista vacía de las búsquedas manuales.
class EmptyListMessage extends StatelessWidget {
  final String title;
  final String subtitle;

  const EmptyListMessage({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: grey)),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: grey)),
        const SizedBox(height: 60),
      ],
    );
  }
}
