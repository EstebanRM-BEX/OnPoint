import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_scan_item_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_sync_badge_widget.dart';

/// Card de paquete expandible para la tab "Listo": el resumen se ve igual
/// que ExpedicionPaqueteRowWidget, pero al tocarla despliega la lista
/// completa de sus productos (mismo patrón visual que CustomExpansionTile
/// de wms_packing/.../tabs/tab5.dart, propio de expedition).
class ExpedicionPaqueteExpandibleWidget extends StatelessWidget {
  final PaqueteExpedicion paquete;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onUndo;

  const ExpedicionPaqueteExpandibleWidget({
    super.key,
    required this.paquete,
    required this.isExpanded,
    required this.onTap,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isExpanded ? const Color.fromARGB(198, 138, 205, 247) : white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            leading: Image.asset(
              'assets/icons/package_barcode.png',
              width: 20,
              height: 20,
              color: primaryColorApp,
            ),
            title: Text(
              paquete.packageName ?? 'Paquete sin nombre',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: red, size: 20),
                  tooltip: 'Deshacer validación',
                  onPressed: onUndo,
                  
                ),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${paquete.items.length} producto(s)',
                    style: const TextStyle(fontSize: 12, color: black)),
                Row(
                  children: [
                    Icon(Icons.qr_code_scanner_sharp,
                        size: 12, color: primaryColorApp),
                    const SizedBox(width: 4),
                    Text('${paquete.packingBarcode}',
                        style: const TextStyle(fontSize: 12, color: black)),
                  ],
                ),
                ExpedicionSyncBadge(syncPending: paquete.syncPending == true),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children:
                    paquete.items.map((i) => ExpedicionScanItemWidget(item: i)).toList(),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
