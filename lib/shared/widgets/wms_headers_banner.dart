import 'package:flutter/material.dart';

/// Banner con secuencia_wms / placa_wms (encabezados de la respuesta).
/// No pinta nada si ambos vienen vacíos.
class WmsHeadersBanner extends StatelessWidget {
  final String secuencia;
  final String placa;
  final EdgeInsetsGeometry padding;

  const WmsHeadersBanner({
    super.key,
    required this.secuencia,
    required this.placa,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  static const _textStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF0369A1),
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    if (secuencia.isEmpty && placa.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF0EA5E9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (secuencia.isNotEmpty)
              Text('Secuencia WMS: $secuencia', style: _textStyle),
            if (placa.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: secuencia.isNotEmpty ? 4 : 0),
                child: Text('Placa WMS: $placa', style: _textStyle),
              ),
          ],
        ),
      ),
    );
  }
}

/// Variante en línea (sin recuadro) para meter dentro de cards existentes:
/// filas "Secuencia WMS: x" / "Placa WMS: y". No pinta nada si están vacías.
class WmsHeadersInline extends StatelessWidget {
  final String secuencia;
  final String placa;
  final Color labelColor;
  final Color valueColor;

  const WmsHeadersInline({
    super.key,
    required this.secuencia,
    required this.placa,
    this.labelColor = const Color(0xFF0369A1),
    this.valueColor = Colors.black,
  });

  Widget _row(String label, String value) => Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (secuencia.isEmpty && placa.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (secuencia.isNotEmpty) _row('Secuencia WMS:', secuencia),
        if (placa.isNotEmpty) _row('Placa WMS:', placa),
      ],
    );
  }
}
