import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/onpoint_header_surface.dart';

/// Cabecera de Información Rápida: botón volver, título y acción opcional a
/// la derecha, sobre el difuminado estándar [OnPointHeaderSurface].
class InfoRapidaHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  const InfoRapidaHeader({
    super.key,
    this.title = 'INFORMACIÓN RÁPIDA',
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return OnPointHeaderSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: HeaderCircleButton(
                icon: Icons.chevron_left,
                iconSize: 26,
                onTap: onBack,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (trailing != null)
              Align(alignment: Alignment.centerRight, child: trailing),
          ],
        ),
      ),
    );
  }
}

/// Botón circular translúcido de la cabecera.
class HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;

  const HeaderCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 40,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

/// Botón de filtro de la cabecera con punto ámbar cuando hay filtro activo.
class HeaderFilterButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const HeaderFilterButton({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HeaderCircleButton(icon: icon, onTap: onTap),
        if (active)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
