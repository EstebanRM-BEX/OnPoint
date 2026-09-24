import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/auth/auth_brand_gradient.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';

/// Fondo estándar de la barra superior en los rediseños OnPoint (referencia:
/// Información Rápida): degradado radial de marca, base redondeada y sombra
/// difuminada. Incluye el SafeArea superior y el aviso de conexión.
class OnPointHeaderSurface extends StatelessWidget {
  final Widget child;

  const OnPointHeaderSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: authBrandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33075985),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const WarningWidgetCubit(), child],
        ),
      ),
    );
  }
}
