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
                  Expanded(
                    child: Text(
                      session.name ?? '',
                      style: TextStyle(
                        color: primaryColorApp,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (session.manejoPropietario == true)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Propietario: ${(session.propietario?.isNotEmpty ?? false) ? session.propietario : "Sin propietario"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: primaryColorApp,
                    ),
                  ),
                ),
              if (session.pickingType != null &&
                  session.pickingType!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Operación: ${session.pickingType}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: primaryColorApp,
                    ),
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: primaryColorApp),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      (session.proveedor?.isNotEmpty ?? false)
                          ? session.proveedor!
                          : 'Sin proveedor',
                      style: TextStyle(
                        fontSize: 12,
                        color: (session.proveedor?.isNotEmpty ?? false)
                            ? black
                            : red,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 14,
                    color: primaryColorApp,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Doc. origen: ${session.origin ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: black),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_sharp,
                    color: primaryColorApp,
                    size: 14,
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
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Almacén: ${session.warehouseName ?? session.warehouseId ?? '-'}',
                    style: const TextStyle(fontSize: 12, color: black),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.add_box_outlined,
                    size: 14,
                    color: primaryColorApp,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Líneas: ${session.numeroLineas ?? 0}',
                    style: const TextStyle(fontSize: 12, color: black),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.inventory_outlined,
                    size: 14,
                    color: primaryColorApp,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Items: ${session.numeroItems ?? 0}',
                    style: const TextStyle(fontSize: 12, color: black),
                  ),
                ],
              ),
              if (session.pesoTotal != null && session.pesoTotal! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.scale_outlined,
                        size: 14,
                        color: primaryColorApp,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Peso total: ${session.pesoTotal}',
                        style: const TextStyle(fontSize: 12, color: black),
                      ),
                    ],
                  ),
                ),
              if (session.manejaTemperatura == true)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.thermostat,
                        size: 14,
                        color: primaryColorApp,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Maneja temperatura: ${session.temperatura ?? 0}°',
                        style: const TextStyle(fontSize: 12, color: black),
                      ),
                    ],
                  ),
                ),
              if (session.backorderId != null && session.backorderId != 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.file_copy,
                        size: 14,
                        color: primaryColorApp,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        session.backorderName ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
