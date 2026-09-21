import 'package:flutter/material.dart';

/// Contenedor base de las tarjetas de la pantalla de configuración.
class ConfigCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ConfigCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Estilos de texto compartidos por las tarjetas de configuración.
abstract final class ConfigText {
  static const sectionTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: Color(0xFF475569),
  );
  static const label = TextStyle(fontSize: 12, color: Color(0xFF64748B));
  static const value = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1E293B),
  );
  static const caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: Color(0xFF94A3B8),
  );
}
