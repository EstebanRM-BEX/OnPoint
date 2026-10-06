import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Fila "icono + label + valor" de [ExpedicionDetalleDatosCardWidget].
class ExpedicionDetalleDato {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  /// Valor en un chip azul (p. ej. Doc. Origen).
  final bool chip;

  /// Valor con avatar de iniciales (operario).
  final bool avatar;

  /// Valor en negrita monoespaciada (fecha).
  final bool mono;

  const ExpedicionDetalleDato({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.chip = false,
    this.avatar = false,
    this.mono = false,
  });
}

/// Tarjeta "Datos de operación y carga" de la tab "Detalles": tiles con
/// Items / Paquetes / Peso total y filas con el resto de los datos.
class ExpedicionDetalleDatosCardWidget extends StatelessWidget {
  final String items;
  final String paquetes;
  final String peso;
  final List<ExpedicionDetalleDato> datos;

  const ExpedicionDetalleDatosCardWidget({
    super.key,
    required this.items,
    required this.paquetes,
    required this.peso,
    required this.datos,
  });

  static const _mono = 'monospace';
  static const _slate = Color(0xFF64748B);

  Widget _stat(String label, String value, {String? unit}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569))),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: primaryColorApp)),
                  if (unit != null) ...[
                    const SizedBox(width: 3),
                    Text(unit,
                        style: const TextStyle(fontSize: 11, color: _slate)),
                  ],
                ],
              ),
            ],
          ),
        ),
      );

  Widget _valor(ExpedicionDetalleDato d) {
    final style = TextStyle(
      fontFamily: d.mono || d.chip ? _mono : null,
      fontSize: 12,
      fontWeight: d.chip || d.mono || d.avatar || d.valueColor != null
          ? FontWeight.w700
          : FontWeight.w500,
      color: d.chip ? primaryColorApp : (d.valueColor ?? const Color(0xFF1E293B)),
    );
    if (d.chip) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(d.value, style: style),
      );
    }
    if (d.avatar) {
      final partes =
          d.value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
      final iniciales =
          partes.take(2).map((e) => e[0].toUpperCase()).join();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (d.valueColor == null)
            CircleAvatar(
              radius: 11,
              backgroundColor: primaryColorApp,
              child: Text(iniciales,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: white)),
            ),
          if (d.valueColor == null) const SizedBox(width: 6),
          Flexible(child: Text(d.value, style: style)),
        ],
      );
    }
    return Text(d.value, textAlign: TextAlign.right, style: style);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('DATOS DE OPERACIÓN Y CARGA',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _slate)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('DETALLE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: primaryColorApp)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _stat('Items', items),
              const SizedBox(width: 8),
              _stat('Paquetes', paquetes),
              const SizedBox(width: 8),
              _stat('Peso total', peso, unit: 'kg'),
            ],
          ),
          const SizedBox(height: 3),
          for (var i = 0; i < datos.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(datos[i].icon, size: 18, color: primaryColorApp),
                  const SizedBox(width: 10),
                  Text('${datos[i].label}:',
                      style: const TextStyle(fontSize: 12, color: _slate)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: _valor(datos[i])),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
