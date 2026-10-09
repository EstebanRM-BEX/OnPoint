import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/onpoint_header_surface.dart';

/// Cabecera de la lista de transferencias (mismo estilo que Pick Cluster):
/// volver, título con sincronizar, filtro "asignadas a mí" y menú de tipos.
class TransferenciasListHeaderWidget extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  /// Filtro "solo las asignadas a mí" activo.
  final bool soloMias;

  /// Transferencias pendientes con el usuario actual como responsable.
  final int misCount;
  final VoidCallback onToggleSoloMias;

  /// Tipos de transferencia para filtrar; el menú solo aparece con más de uno.
  final List<String> tipos;
  final ValueChanged<String> onTipoSelected;

  const TransferenciasListHeaderWidget({
    super.key,
    required this.onBack,
    required this.onRefresh,
    required this.soloMias,
    required this.misCount,
    required this.onToggleSoloMias,
    required this.tipos,
    required this.onTipoSelected,
  });

  @override
  Widget build(BuildContext context) {
    return OnPointHeaderSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
        child: Row(
          children: [
            _CircleAction(
              icon: Icons.arrow_back,
              tooltip: 'Volver',
              onTap: onBack,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'TRANSFERENCIAS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _CircleAction(
                    icon: Icons.sync,
                    tooltip: 'Sincronizar',
                    size: 32,
                    iconSize: 18,
                    onTap: onRefresh,
                  ),
                ],
              ),
            ),
            _CircleAction(
              tooltip: soloMias
                  ? 'Mostrar todas'
                  : 'Asignadas a mí ($misCount)',
              onTap: onToggleSoloMias,
              child: Badge(
                isLabelVisible: misCount > 0,
                label: Text('$misCount'),
                child: Icon(
                  soloMias ? Icons.person : Icons.person_outline,
                  color: soloMias ? Colors.amber : Colors.white,
                  size: 22,
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: tipos.length > 1 ? _buildTiposMenu() : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiposMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Filtrar por tipo',
      color: white,
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
      onSelected: onTipoSelected,
      itemBuilder: (_) => [...tipos, 'todas'].map((tipo) {
        final isTodas = tipo.toLowerCase() == 'todas';
        return PopupMenuItem<String>(
          value: tipo,
          child: Row(
            children: [
              Icon(
                isTodas ? Icons.select_all : Icons.file_upload_outlined,
                color: isTodas ? Colors.grey : primaryColorApp,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                isTodas ? 'Todas' : tipo,
                style: const TextStyle(color: black, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _CircleAction({
    this.icon,
    this.child,
    required this.tooltip,
    required this.onTap,
    this.size = 40,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: child ?? Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}
