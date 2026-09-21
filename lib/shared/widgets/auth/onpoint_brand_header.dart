import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Cabecera de marca de las pantallas de acceso (servidor y login):
/// emblema, título y badge de versión.
///
/// La versión se lee de [PackageInfo] y no del `UserBloc`: el estado de ese
/// bloc cambia durante el login (UserLoaded, errores…) y la versión
/// desaparecía de la cabecera en cuanto dejaba de ser `DeviceInfoLoaded`.
class OnPointBrandHeader extends StatelessWidget {
  const OnPointBrandHeader({super.key});

  // Un solo Future por proceso: evita re-consultar la plataforma en cada
  // rebuild (teclado, validaciones, etc.).
  static final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        children: [
          const _Emblem(),
          const SizedBox(height: 16),
          const Text(
            'Bienvenido a OnPoint',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (_, snapshot) =>
                _VersionBadge(version: snapshot.data?.version ?? ''),
          ),
        ],
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7DD3FC).withOpacity(0.35),
            blurRadius: 18,
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        // Logo OnPoint (negro sobre transparente) teñido con el color de
        // marca. cacheWidth: el PNG es 640px y se pinta a ~44px; decodificarlo
        // a tamaño completo solo gasta memoria.
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            'assets/icons/icon3602.png',
            color: primaryColorApp,
            colorBlendMode: BlendMode.srcIn,
            cacheWidth: 144,
            filterQuality: FilterQuality.medium,
            semanticLabel: 'OnPoint',
          ),
        ),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String version;
  const _VersionBadge({required this.version});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF34D399),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Versión $version',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
