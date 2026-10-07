import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/app_inspector/presentation/app_inspector_controller.dart';
import 'config_card.dart';

/// Interruptor del botón flotante del inspector (pantallas, diálogos, blocs).
class AppInspectorCard extends StatelessWidget {
  const AppInspectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppInspectorController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ConfigCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColorApp.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_tree_outlined,
                color: primaryColorApp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inspector de la app',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    controller.visible
                        ? 'Botón flotante visible'
                        : 'Pantallas, diálogos y blocs',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: controller.visible,
              activeColor: Colors.white,
              activeTrackColor: primaryColorApp,
              onChanged: controller.setVisible,
            ),
          ],
        ),
      ),
    );
  }
}
