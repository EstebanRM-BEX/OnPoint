import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/shared/widgets/onpoint_header_surface.dart';

/// Cabecera del detalle de batch: volver, nombre del batch, impresión del
/// batch y píldora flotante con el % de unidades separadas.
class DetailBatchHeader extends StatelessWidget {
  final String batchName;
  final String progress;
  final VoidCallback onBack;
  final VoidCallback onPrint;
  final VoidCallback onProgressInfo;

  const DetailBatchHeader({
    super.key,
    required this.batchName,
    required this.progress,
    required this.onBack,
    required this.onPrint,
    required this.onProgressInfo,
  });

  /// Alto que la píldora sobresale por debajo de la cabecera.
  static const pillOverlap = 22.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: pillOverlap),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          OnPointHeaderSurface(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 36),
              child: Row(
                children: [
                  _SquareAction(
                    icon: Icons.chevron_left,
                    tooltip: 'Volver',
                    onTap: onBack,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'VERIFICACIÓN & SEPARACIÓN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          batchName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SquareAction(
                    icon: Icons.print_outlined,
                    tooltip: 'Imprimir batch',
                    onTap: onPrint,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -pillOverlap,
            child: _ProgressPill(progress: progress, onInfo: onProgressInfo),
          ),
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SquareAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final String progress;
  final VoidCallback onInfo;

  const _ProgressPill({required this.progress, required this.onInfo});

  Color _toneFor(double value) {
    if (value >= 100) return const Color(0xFF059669);
    if (value < 20) return const Color(0xFFDC2626);
    if (value < 50) return const Color(0xFFEA580C);
    return const Color(0xFFD97706);
  }

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(double.tryParse(progress) ?? 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ClusterPalette.slate100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          const Text(
            'Unidades separadas: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ClusterPalette.slate600,
            ),
          ),
          Text(
            '$progress%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
          IconButton(
            tooltip: 'Cómo se calcula',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: onInfo,
            icon: const Icon(
              Icons.help_outline,
              color: ClusterPalette.brand600,
            ),
          ),
        ],
      ),
    );
  }
}
