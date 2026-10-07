import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Fila "Etiqueta: valor" (o ícono + valor) de las tarjetas y del detalle.
class InfoLineaPack extends StatelessWidget {
  final String? etiqueta;
  final IconData? icono;
  final String valor;

  /// Texto si [valor] viene vacío; se muestra en rojo.
  final String? vacio;
  final Color? colorValor;
  final bool negrita;
  final Widget? trailing;

  const InfoLineaPack({
    super.key,
    this.etiqueta,
    this.icono,
    required this.valor,
    this.vacio,
    this.colorValor,
    this.negrita = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final sinValor = valor.trim().isEmpty;
    final texto = sinValor ? (vacio ?? '') : valor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icono != null) ...[
            Icon(icono, color: primaryColorApp, size: 15),
            const SizedBox(width: 5),
          ],
          if (etiqueta != null)
            Text(
              '$etiqueta: ',
              style: TextStyle(fontSize: 12, color: primaryColorApp),
            ),
          Expanded(
            child: Text(
              texto,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
                color: sinValor && vacio != null ? red : (colorValor ?? black),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
