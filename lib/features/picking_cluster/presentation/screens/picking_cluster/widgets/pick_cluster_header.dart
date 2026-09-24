import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/onpoint_header_surface.dart';

/// Cabecera de Pick Cluster: volver, título con sincronizar y menú de
/// ordenamiento sobre el degradado de marca.
class PickClusterHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final Widget? menu;

  const PickClusterHeader({
    super.key,
    required this.onBack,
    required this.onRefresh,
    this.menu,
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
                      'PICK CLUSTER',
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
            SizedBox(width: 40, child: menu),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _CircleAction({
    required this.icon,
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
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}
