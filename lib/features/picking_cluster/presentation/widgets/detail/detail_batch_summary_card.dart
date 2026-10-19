import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/picking_batch.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/batch_pedidos_dialog.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/cluster_zonas_trabajo_dialog.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';

/// Resumen del batch actual (misma info que PickingBatchCard del listado más
/// secuencia_wms / placa_wms). Comprimido por defecto: zona + nombre; al
/// expandir muestra el resto.
class DetailBatchSummaryCard extends StatefulWidget {
  final PickingBatch batch;
  final String secuencia;
  final String placa;

  const DetailBatchSummaryCard({
    super.key,
    required this.batch,
    this.secuencia = '',
    this.placa = '',
  });

  @override
  State<DetailBatchSummaryCard> createState() => _DetailBatchSummaryCardState();
}

class _DetailBatchSummaryCardState extends State<DetailBatchSummaryCard> {
  static final _qtyFormat = NumberFormat('#,##0.##');
  static const _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: ClusterPalette.slate400,
  );

  bool _expanded = false;

  PickingBatch get batch => widget.batch;

  bool get _isStarted =>
      batch.startTimePick != null && batch.startTimePick.toString().isNotEmpty;

  bool get _handlesOwner =>
      batch.manejoPropietario == 1 || batch.manejoPropietario == true;

  String _formatQty(dynamic value) {
    final number = value is num ? value : num.tryParse('${value ?? ''}');
    return number == null ? '0' : _qtyFormat.format(number);
  }

  String _formatDate() {
    final raw = batch.scheduledDate;
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    return parsed == null ? 'Sin fecha' : DateFormat('dd/MM/yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ClusterPalette.slate200),
          boxShadow: ClusterPalette.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  if (_expanded) ...[
                    const SizedBox(height: 10),
                    _buildDetails(),
                    if (batch.zonasTrabajo.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildZonas(),
                    ],
                    const SizedBox(height: 10),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: ClusterPalette.slate100,
                    ),
                    const SizedBox(height: 10),
                    _buildMetrics(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final zona = batch.zonaEntrega ?? '';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (zona.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ClusterPalette.brand50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ClusterPalette.brand100),
                  ),
                  child: Text(
                    zona.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: ClusterPalette.brand600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                batch.name ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ClusterPalette.slate900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        if (_isStarted)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Batch iniciado',
            icon: const Icon(
              Icons.schedule,
              size: 18,
              color: ClusterPalette.amber500,
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => DialogInfo(
                title: 'Tiempo de inicio',
                body: 'Este batch fue iniciado a las ${batch.startTimePick}',
              ),
            ),
          ),
        Icon(
          _expanded ? Icons.expand_less : Icons.expand_more,
          color: ClusterPalette.brand600,
        ),
      ],
    );
  }

  Widget _labelValue(String label, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text.rich(
          TextSpan(
            text: label,
            style: _labelStyle,
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? ClusterPalette.slate800,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.secuencia.isNotEmpty)
          _labelValue('Secuencia WMS: ', widget.secuencia,
              valueColor: ClusterPalette.brand700),
        if (widget.placa.isNotEmpty)
          _labelValue('Placa WMS: ', widget.placa,
              valueColor: ClusterPalette.brand700),
        if (_handlesOwner)
          _labelValue(
            'Propietario: ',
            batch.propietario?.isNotEmpty == true
                ? batch.propietario!
                : 'No asignado',
          ),
        _labelValue('Tipo de operación: ', batch.pickingTypeId ?? '',
            valueColor: ClusterPalette.brand700),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: ClusterPalette.brand500),
            const SizedBox(width: 4),
            Text(
              _formatDate(),
              style:
                  const TextStyle(fontSize: 11, color: ClusterPalette.slate500),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('•',
                  style:
                      TextStyle(fontSize: 11, color: ClusterPalette.slate300)),
            ),
            const Icon(Icons.person_outline,
                size: 14, color: ClusterPalette.slate400),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                batch.userName ?? 'Sin responsable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ClusterPalette.slate700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZonas() {
    final zonas = batch.zonasTrabajo;
    return Material(
      color: ClusterPalette.brand50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => ClusterZonasTrabajoDialog.show(
          context,
          batchName: batch.name ?? '',
          zonas: zonas,
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ClusterPalette.brand100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined,
                  size: 15, color: ClusterPalette.brand600),
              const SizedBox(width: 6),
              Text(
                'Ver zonas (${zonas.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ClusterPalette.brand600,
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: ClusterPalette.brand600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    final pedidos = batch.pedidosValidate;
    return Row(
      children: [
        Expanded(
          child: _Metric(
            label: 'Pedidos',
            value: _formatQty(pedidos.length),
            onTap: pedidos.isEmpty
                ? null
                : () => BatchPedidosDialog.show(
                      context,
                      batchName: batch.name ?? '',
                      pedidos: pedidos,
                    ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metric(label: 'Líneas', value: _formatQty(batch.countItems)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Metric(
            label: 'Unidades',
            value: _formatQty(batch.totalQuantityItems),
            highlighted: true,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;
  final VoidCallback? onTap;

  const _Metric({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor =
        highlighted ? ClusterPalette.brand800 : ClusterPalette.slate500;
    return Material(
      color: highlighted ? ClusterPalette.brand50 : ClusterPalette.slate50,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlighted
                  ? ClusterPalette.brand100
                  : ClusterPalette.slate100,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, size: 14, color: labelColor),
                ],
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        highlighted ? FontWeight.w800 : FontWeight.w700,
                    color: highlighted
                        ? ClusterPalette.brand700
                        : ClusterPalette.slate900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
