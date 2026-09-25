import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/auth/auth_brand_gradient.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';

/// Cabecera de Información Rápida: botón volver y título sobre el degradado
/// de marca, con base redondeada.
class InfoRapidaHeader extends StatelessWidget {
  final VoidCallback onBack;

  const InfoRapidaHeader({super.key, required this.onBack});

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
          children: [
            const WarningWidgetCubit(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.white.withOpacity(0.15),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onBack,
                        customBorder: const CircleBorder(),
                        child: const SizedBox.square(
                          dimension: 40,
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 52),
                    child: Text(
                      'INFORMACIÓN RÁPIDA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
