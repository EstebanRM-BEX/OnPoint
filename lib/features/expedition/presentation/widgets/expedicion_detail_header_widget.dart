import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/onpoint_header_surface.dart';

/// Cabecera de expedition_screen.dart: botón atrás, título centrado y barra de
/// pestañas tipo "pill" (Detalles / Por hacer / Listo) con contadores.
class ExpedicionDetailHeaderWidget extends StatelessWidget {
  final TabController controller;
  final int porHacerCount;
  final int listoCount;
  final VoidCallback onBack;

  const ExpedicionDetailHeaderWidget({
    super.key,
    required this.controller,
    required this.porHacerCount,
    required this.listoCount,
    required this.onBack,
  });

  Widget _tab(IconData icon, String text, {int? badge, Color? badgeColor}) {
    return Tab(
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              top: -5,
              left: -20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnPointHeaderSurface(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'EXPEDICIÓN',
                    style: TextStyle(
                      color: white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: white.withOpacity(0.12)),
              ),
              child: TabBar(
                controller: controller,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: primaryColorApp,
                unselectedLabelColor: white,
                splashBorderRadius: BorderRadius.circular(12),
                tabs: [
                  _tab(Icons.info_outline, 'Detalles'),
                  _tab(
                    Icons.assignment_outlined,
                    'Por hacer',
                    badge: porHacerCount,
                    badgeColor: red,
                  ),
                  _tab(
                    Icons.check_circle_outline,
                    'Listo',
                    badge: listoCount,
                    badgeColor: green,
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
