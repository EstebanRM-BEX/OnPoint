import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import '../../../../domain/entities/picking_batch.dart';

class PickingBatchCard extends StatelessWidget {
  final PickingBatch batch;
  final VoidCallback onTap;

  const PickingBatchCard({super.key, required this.batch, required this.onTap});

  static final _qtyFormat = NumberFormat('#,##0.##');

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
    return parsed == null
        ? 'Sin fecha'
        : DateFormat('dd/MM/yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 10),
                _buildDetails(),
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: ClusterPalette.slate100,
                ),
                const SizedBox(height: 10),
                _buildMetrics(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final zona = batch.zonaEntrega ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (zona.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ClusterPalette.slate900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        if (_isStarted) ...[
          const SizedBox(width: 4),
          _StartedBadge(
            onTap: () => showDialog(
              context: context,
              builder: (_) => DialogInfo(
                title: 'Tiempo de inicio',
                body: 'Este batch fue iniciado a las ${batch.startTimePick}',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetails() {
    const labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: ClusterPalette.slate400,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_handlesOwner)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text.rich(
              TextSpan(
                text: 'Propietario: ',
                style: labelStyle,
                children: [
                  batch.propietario?.isNotEmpty == true
                      ? TextSpan(
                          text: batch.propietario,
                          style: const TextStyle(
                            color: ClusterPalette.slate800,
                          ),
                        )
                      : const TextSpan(
                          text: 'No asignado',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                ],
              ),
            ),
          ),
        Text.rich(
          TextSpan(
            text: 'Tipo de operación: ',
            style: labelStyle,
            children: [
              TextSpan(
                text: batch.pickingTypeId ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ClusterPalette.brand700,
                ),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: ClusterPalette.brand500,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(),
              style: const TextStyle(
                fontSize: 11,
                color: ClusterPalette.slate500,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '•',
                style: TextStyle(fontSize: 11, color: ClusterPalette.slate300),
              ),
            ),
            const Icon(
              Icons.person_outline,
              size: 14,
              color: ClusterPalette.slate400,
            ),
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

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.receipt_long_outlined,
            label: 'Pedidos',
            value: _formatQty(batch.pedidosValidate.length),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            icon: Icons.format_list_bulleted,
            label: 'Líneas',
            value: _formatQty(batch.countItems),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            icon: Icons.inventory_2_outlined,
            label: 'Unidades',
            value: _formatQty(batch.totalQuantityItems),
            highlighted: true,
          ),
        ),
      ],
    );
  }
}

class _StartedBadge extends StatelessWidget {
  final VoidCallback onTap;

  const _StartedBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Batch iniciado',
      child: Material(
        color: ClusterPalette.slate50,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ClusterPalette.slate100),
            ),
            child: const Icon(
              Icons.schedule,
              size: 16,
              color: ClusterPalette.amber500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = highlighted
        ? ClusterPalette.brand800
        : ClusterPalette.slate500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted ? ClusterPalette.brand50 : ClusterPalette.slate50,
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
              Icon(
                icon,
                size: 13,
                color: highlighted
                    ? ClusterPalette.brand600
                    : ClusterPalette.slate400,
              ),
              const SizedBox(width: 4),
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
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: highlighted ? FontWeight.w800 : FontWeight.w700,
                color: highlighted
                    ? ClusterPalette.brand700
                    : ClusterPalette.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
