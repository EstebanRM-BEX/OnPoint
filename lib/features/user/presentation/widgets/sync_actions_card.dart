import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'config_card.dart';

/// Acción de descarga/sincronización de tablas maestras.
class SyncAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const SyncAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

/// Tarjeta con la acción principal ("Ver Almacenes") y las descargas.
class SyncActionsCard extends StatelessWidget {
  final SyncAction primary;
  final List<SyncAction> actions;

  const SyncActionsCard({
    super.key,
    required this.primary,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return ConfigCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrimaryActionButton(action: primary),
          const SizedBox(height: 12),
          for (final action in actions) ...[
            _SecondaryActionButton(action: action),
            if (action != actions.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final SyncAction action;
  const _PrimaryActionButton({required this.action});

  static const _radius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        gradient: const LinearGradient(
          colors: [Color(0xFF00589A), primaryColorApp],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColorApp.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: _radius,
        child: InkWell(
          onTap: action.onPressed,
          borderRadius: _radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(action.icon, size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final SyncAction action;
  const _SecondaryActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: action.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(action.icon, size: 16, color: primaryColorApp),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const Icon(
                Icons.download_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
