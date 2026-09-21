import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import '../models/permission_section.dart';
import 'config_card.dart';
import 'dialog_info_widget.dart';

/// Tarjeta de un grupo de permisos (solo lectura).
class PermissionSectionCard extends StatelessWidget {
  final PermissionSection section;

  const PermissionSectionCard({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return ConfigCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: section.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title.toUpperCase(),
                  style: ConfigText.sectionTitle.copyWith(
                    color: primaryColorApp,
                  ),
                ),
              ),
              if (section.tag != null) _Tag(section.tag!, section.accent),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          for (var i = 0; i < section.items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
            _PermissionRow(item: section.items[i]),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color.lerp(color, Colors.black, 0.25),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final PermissionItem item;
  const _PermissionRow({required this.item});

  void _showInfo(BuildContext context) => showDialog(
    context: context,
    builder: (_) => DialogInfo(title: item.infoTitle, body: item.infoBody),
  );

  @override
  Widget build(BuildContext context) {
    final value = item.value;
    return InkWell(
      // Toda la fila abre la ayuda: objetivo táctil grande en PDA.
      onTap: () => _showInfo(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        // Columnas fijas a la derecha: [estado][ayuda]. El texto ocupa el
        // resto (Expanded), así los checks y los iconos de ayuda quedan
        // alineados verticalmente sin importar el largo del texto.
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (value is bool)
              _ReadOnlyCheck(checked: value, label: item.label)
            else
              _OptionChip(value.toString()),
            const SizedBox(width: 12),
            const Icon(Icons.help_outline, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyCheck extends StatelessWidget {
  final bool checked;
  final String label;
  const _ReadOnlyCheck({required this.checked, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      checked: checked,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: checked ? primaryColorApp : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: checked ? primaryColorApp : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: checked
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String text;
  const _OptionChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColorApp.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColorApp.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryColorApp,
        ),
      ),
    );
  }
}
