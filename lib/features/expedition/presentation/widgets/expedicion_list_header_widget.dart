import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/onpoint_header_surface.dart';

/// Cabecera de las listas de expedición / packing: volver, título, refrescar y
/// menú de orden/filtro sobre el degradado de marca (mismo estilo que Pick
/// Cluster).
class ExpedicionListHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final Widget? menu;

  /// Botón ámbar visible cuando hay un filtro de propietario activo.
  final VoidCallback? onPropietarioActivoTap;

  const ExpedicionListHeaderWidget({
    super.key,
    required this.onBack,
    this.title = 'EXPEDICIONES',
    required this.onRefresh,
    this.menu,
    this.onPropietarioActivoTap,
  });

  @override
  Widget build(BuildContext context) {
    return OnPointHeaderSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
        child: Row(
          children: [
            _action(Icons.arrow_back, 'Volver', onBack),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (onPropietarioActivoTap != null)
              _action(
                Icons.person_search_outlined,
                'Filtro de propietario',
                onPropietarioActivoTap!,
                color: Colors.amber,
              ),
            _action(Icons.refresh, 'Refrescar', onRefresh),
            SizedBox(width: 40, child: menu),
          ],
        ),
      ),
    );
  }

  Widget _action(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}
