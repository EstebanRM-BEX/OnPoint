import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/onpoint_header_surface.dart';

/// Cabecera de validación de batch: nombre del batch, subtítulo y píldora
/// de progreso de unidades separadas sobre el degradado de marca.
class ValidateBatchHeader extends StatelessWidget {
  final String batchName;
  final String progress;
  final VoidCallback onBack;
  final Widget menu;

  const ValidateBatchHeader({
    super.key,
    required this.batchName,
    required this.progress,
    required this.onBack,
    required this.menu,
  });

  @override
  Widget build(BuildContext context) {
    return OnPointHeaderSurface(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: onBack,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        batchName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'VALIDACIÓN DE PEDIDOS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 48, child: menu),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: _ProgressPill(progress: progress),
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final String progress;

  const _ProgressPill({required this.progress});

  /// Tonos claros legibles sobre el degradado azul.
  Color _toneFor(double value) {
    if (value >= 100) return const Color(0xFF6EE7B7);
    if (value < 20) return const Color(0xFFFCA5A5);
    if (value < 50) return const Color(0xFFFDBA74);
    return const Color(0xFFFDE047);
  }

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(double.tryParse(progress) ?? 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              text: 'Unidades separadas: ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: '$progress%',
                  style: TextStyle(color: tone, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
