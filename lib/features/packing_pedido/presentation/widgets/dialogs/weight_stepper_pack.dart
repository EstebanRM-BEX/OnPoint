// Copia de packing-batch/screens/widgets/others para que el feature no
// dependa del módulo legacy.

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Campo de peso (kg) con botones − / + y preajustes rápidos.
///
/// El valor se lee del [controller]; el teclado decimal de la PDA en español
/// escribe "1,5", por eso al sumar/restar se acepta coma o punto y se escribe
/// siempre con punto.
class WeightStepperPack extends StatelessWidget {
  const WeightStepperPack({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  static const double _step = 0.5;
  static const List<double> _presets = [0.5, 1.0, 2.5, 5.0];

  double get _current =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0.0;

  void _set(double value) {
    final v = value < 0 ? 0.0 : value;
    controller.text = v.toStringAsFixed(2);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.scale_outlined, size: 15, color: primaryColorApp),
            const SizedBox(width: 6),
            const Text(
              'PESO (KG)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF334155),
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF43F5E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                tooltip: 'Disminuir 0.5 kg',
                onTap: () => _set(_current - _step),
              ),
              Expanded(
                child: TextFormField(
                  key: const ValueKey('weight_field'),
                  controller: controller,
                  focusNode: focusNode,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                    suffixText: 'KG',
                    suffixStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                tooltip: 'Aumentar 0.5 kg',
                onTap: () => _set(_current + _step),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'PREAJUSTES:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
              for (final p in _presets)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _set(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${p.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F5F9),
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: 18, color: const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}
