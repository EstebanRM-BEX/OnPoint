import 'package:flutter/material.dart';
import '../../domain/entities/user_configuration.dart';
import '../models/permission_section.dart';
import 'permission_section_card.dart';

/// Bloque "Privilegios de operación": separador + una tarjeta por módulo,
/// filtradas según el rol del usuario.
class PermissionsWidget extends StatelessWidget {
  final UserProfile profile;

  const PermissionsWidget({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final sections = PermissionSection.fromProfile(
      profile,
    ).where((s) => s.isVisibleFor(profile.rol)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionDivider('PRIVILEGIOS DE OPERACIÓN'),
        for (final section in sections) ...[
          const SizedBox(height: 14),
          PermissionSectionCard(section: section),
        ],
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String text;
  const _SectionDivider(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }
}
