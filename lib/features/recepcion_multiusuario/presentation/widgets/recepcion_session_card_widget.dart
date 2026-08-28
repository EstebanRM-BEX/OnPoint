import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';

class RecepcionSessionCardWidget extends StatelessWidget {
  const RecepcionSessionCardWidget({super.key, required this.session});

  final RecepcionSession session;

  @override
  Widget build(BuildContext context) {
    final progress = (session.progressPercent ?? 0.0).clamp(0.0, 1.0);
    final progressLabel = '${(progress * 100).toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Card(
        elevation: 3,
        color: white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: primaryColorApp,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    session.name ?? '',
                    style: TextStyle(
                      color: primaryColorApp,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_sharp,
                    color: primaryColorApp,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      session.pickingName ?? '',
                      style: const TextStyle(fontSize: 12, color: black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.warehouse_outlined,
                    color: primaryColorApp,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Almacén: ${session.warehouseId ?? '-'}',
                    style: const TextStyle(fontSize: 12, color: black),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: grey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? green : primaryColorApp,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso: $progressLabel',
                    style: TextStyle(fontSize: 11, color: primaryColorApp),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        color: session.pendingTasks == 0 ? green : red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tareas pendientes: ${session.pendingTasks ?? 0}',
                        style: TextStyle(
                          fontSize: 11,
                          color: session.pendingTasks == 0 ? green : red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
