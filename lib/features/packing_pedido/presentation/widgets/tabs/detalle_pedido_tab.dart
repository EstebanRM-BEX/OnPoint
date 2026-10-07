import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_observacion_expedicion_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_observacion_widget.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_resultados.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/info_linea_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';

/// Pestaña "Detalles": datos del pedido, avance y botón de confirmar.
class DetallePedidoTab extends StatelessWidget {
  final PedidoPackDetalle detalle;

  /// null = botón oculto (sin permiso o pedido terminado).
  final VoidCallback? onConfirmar;

  const DetallePedidoTab({
    super.key,
    required this.detalle,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final p = detalle.pedido;
    final fmt = PackFormatos.cantidad;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          p.name,
          style: TextStyle(
            fontSize: 15,
            color: primaryColorApp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        InfoLineaPack(
          etiqueta: 'Prioridad',
          valor: p.esPrioritario ? 'Alta' : 'Normal',
          colorValor: p.esPrioritario ? red : black,
        ),
        InfoLineaPack(
          etiqueta: 'Zona de entrega',
          valor: p.zonaEntrega,
          vacio: 'Sin zona de entrega',
          negrita: true,
          colorValor: p.esPrioritario ? red : primaryColorApp,
        ),
        InfoLineaPack(etiqueta: 'Operación', valor: p.pickingType),
        if (p.observacion.isNotEmpty)
          ExpedicionObservacionWidget(
            observacion: p.observacion,
            onVerMas: () => showDialog(
              context: context,
              builder: (_) =>
                  DialogObservacionExpedicionWidget(observacion: p.observacion),
            ),
          ),
        InfoLineaPack(etiqueta: 'Referencia', valor: p.referencia),
        const Divider(color: black, thickness: 1, height: 12),
        InfoLineaPack(
          icono: Icons.calendar_month_sharp,
          valor: p.fechaCreacion == null
              ? ''
              : DateFormat('dd/MM/yyyy hh:mm').format(p.fechaCreacion!),
          vacio: 'Sin fecha',
        ),
        InfoLineaPack(
          etiqueta: 'Proveedor',
          valor: p.proveedor,
          vacio: 'Sin proveedor',
        ),
        InfoLineaPack(
          etiqueta: 'Contacto',
          valor: p.contactoName,
          vacio: 'Sin contacto',
        ),
        InfoLineaPack(etiqueta: 'Total productos', valor: '${p.numeroLineas}'),
        InfoLineaPack(etiqueta: 'Total de unidades', valor: fmt(p.numeroItems)),
        InfoLineaPack(
          etiqueta: 'Productos empacados',
          valor: '${detalle.empacados.length}',
        ),
        InfoLineaPack(
          etiqueta: 'Número de paquetes',
          valor: '${detalle.paquetes.length}',
        ),
        InfoLineaPack(etiqueta: 'Destino', valor: p.locationDestName),
        InfoLineaPack(
          icono: Icons.person_rounded,
          valor: p.responsable,
          vacio: 'Sin responsable',
        ),
        InfoLineaPack(
          icono: Icons.timer,
          etiqueta: 'Tiempo de inicio',
          valor: p.startTimeTransfer,
        ),
        const SizedBox(height: 14),
        _Avance(detalle: detalle),
        const SizedBox(height: 18),
        if (onConfirmar != null)
          ElevatedButton(
            onPressed: onConfirmar,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Confirmar pedido',
              style: TextStyle(color: white, fontSize: 13),
            ),
          ),
        if (p.isTerminate)
          const Center(
            child: Text(
              'Pedido terminado',
              style: TextStyle(color: green, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

class _Avance extends StatelessWidget {
  final PedidoPackDetalle detalle;
  const _Avance({required this.detalle});

  @override
  Widget build(BuildContext context) {
    final pct = detalle.progresoEmpacado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Empacado: ${pct.toStringAsFixed(0)} %',
          style: TextStyle(fontSize: 12, color: primaryColorApp),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            color: pct >= 100 ? green : primaryColorApp,
          ),
        ),
      ],
    );
  }
}
