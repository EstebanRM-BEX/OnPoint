import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Icono de prefijo de los campos de acceso: color de marca sobre un fondo
/// suave. Compartido para que servidor y login usen el mismo estilo.
class AuthFieldIcon extends StatelessWidget {
  final IconData icon;

  const AuthFieldIcon(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: primaryColorApp.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColorApp, size: 18),
      ),
    );
  }
}
