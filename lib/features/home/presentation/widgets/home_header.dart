import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Cabecera del home sobre la banda de marca: rol, botón salir, avatar,
/// nombre, correo, base de datos y versión.
class HomeHeader extends StatelessWidget {
  final String name;
  final String email;
  final String rol;
  final String database;
  final String version;
  final VoidCallback onProfileTap;
  final VoidCallback onLogout;

  const HomeHeader({
    super.key,
    required this.name,
    required this.email,
    required this.rol,
    required this.database,
    required this.version,
    required this.onProfileTap,
    required this.onLogout,
  });

  static const _roleLabels = {
    'admin': 'Administrador',
    'picking': 'Picking',
    'packing': 'Packing',
    'reception': 'Recepción',
    'transfer': 'Transferencia',
    'inventory': 'Inventario',
  };

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts[1][0] : ''))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rol.isNotEmpty) _RoleBadge(_roleLabels[rol] ?? rol),
              const Spacer(),
              _LogoutButton(onPressed: onLogout),
            ],
          ),
          const SizedBox(height: 12),
          // Toda la zona de perfil abre la configuración del usuario.
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                _Avatar(initials: _initials),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_outlined,
                            size: 16,
                            color: Color(0xFFBAE6FD),
                          ),
                        ],
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            Icons.domain,
                            size: 13,
                            color: Color(0xFFBAE6FD),
                          ),
                          _MonoChip(database),
                          if (version.isNotEmpty) _MonoChip('v$version'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String text;
  const _RoleBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFDE68A),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _LogoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.1),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'Salir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFE0F2FE)],
            ),
          ),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryColorApp,
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF075985), width: 2),
            ),
            child: const Icon(Icons.check, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _MonoChip extends StatelessWidget {
  final String text;
  const _MonoChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontFamily: 'monospace',
          color: Color(0xFFE0F2FE),
        ),
      ),
    );
  }
}
