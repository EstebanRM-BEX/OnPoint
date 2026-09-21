import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/auth/auth_brand_gradient.dart';

/// Cabecera de la pantalla de configuración: botón volver y título.
class ConfigHeader extends StatelessWidget {
  final VoidCallback onBack;

  const ConfigHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: authBrandGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          // Padding inferior extra: la primera tarjeta solapa la cabecera.
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          // Stack: el título queda centrado en la pantalla sin depender
          // del ancho del botón volver.
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _BackButton(onPressed: onBack),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 96),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CONFIGURACIÓN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Color(0xFFBAE6FD),
                      ),
                    ),
                    Text(
                      'TERMINAL MÓVIL',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 16, color: primaryColorApp),
              SizedBox(width: 6),
              Text(
                'Volver',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primaryColorApp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
