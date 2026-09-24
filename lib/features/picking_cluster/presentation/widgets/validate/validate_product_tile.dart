import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';

/// Producto dentro de un pedido a validar: nombre con código, lote,
/// novedad y unidades pedidas vs. separadas.
class ValidateProductTile extends StatelessWidget {
  final BatchProduct product;

  const ValidateProductTile({super.key, required this.product});

  static num _toNum(dynamic value) =>
      value is num ? value : num.tryParse('${value ?? ''}') ?? 0;

  static final _codePrefix = RegExp(r'^(\[[^\]]+\])\s*(.*)$');

  @override
  Widget build(BuildContext context) {
    final qty = _toNum(product.quantity);
    final qtySeparate = _toNum(product.quantitySeparate);
    final complete = qty > 0 && qtySeparate >= qty;
    final observation = product.observation;
    final lote = '${product.lote ?? ''}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClusterPalette.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClusterPalette.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildName(),
          if (product.isSendOdoo != 1) ...[
            const SizedBox(height: 6),
            _UnsentChip(offline: product.isSendOdoo == 0),
          ],
          if (lote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Lote: $lote',
              style: const TextStyle(
                fontSize: 12,
                color: ClusterPalette.slate600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Novedad:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ClusterPalette.slate500,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ClusterPalette.slate200),
                  ),
                  child: Text(
                    observation != null && observation.isNotEmpty
                        ? observation
                        : 'Sin novedad',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: ClusterPalette.slate600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: ClusterPalette.slate200),
          const SizedBox(height: 10),
          // Wrap: en pantallas angostas el badge baja de línea en vez de
          // desbordar.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: ClusterPalette.brand100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 13,
                      color: ClusterPalette.brand600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: _qtyText(
                      'Unidades: ',
                      qty,
                      ClusterPalette.slate700,
                      ClusterPalette.slate900,
                    ),
                  ),
                ],
              ),
              _SeparatedBadge(quantity: qtySeparate, complete: complete),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildName() {
    final raw = '${product.productId ?? 'Producto desconocido'}';
    final match = _codePrefix.firstMatch(raw);
    const nameStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: ClusterPalette.slate800,
      height: 1.35,
    );
    if (match == null) return Text(raw, style: nameStyle);
    return Text.rich(
      TextSpan(
        style: nameStyle,
        children: [
          TextSpan(
            text: '${match.group(1)} ',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: ClusterPalette.brand700,
            ),
          ),
          TextSpan(text: match.group(2)),
        ],
      ),
    );
  }
}

Widget _qtyText(String label, num value, Color labelColor, Color valueColor) {
  return Text.rich(
    TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ),
      children: [
        TextSpan(
          text: '$value',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

/// Producto que aún no llega al WMS: bloquea la validación del pedido.
class _UnsentChip extends StatelessWidget {
  /// true: guardado sin conexión (is_send_odoo = 0); false: sin procesar.
  final bool offline;

  const _UnsentChip({required this.offline});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.wifi_off : Icons.schedule,
              size: 12,
              color: const Color(0xFF92400E),
            ),
            const SizedBox(width: 4),
            Text(
              offline ? 'Pendiente de envío' : 'Sin enviar al WMS',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeparatedBadge extends StatelessWidget {
  final num quantity;
  final bool complete;

  const _SeparatedBadge({required this.quantity, required this.complete});

  static const _emerald50 = Color(0xFFECFDF5);
  static const _emerald200 = Color(0xFFA7F3D0);
  static const _emerald600 = Color(0xFF059669);
  static const _emerald700 = Color(0xFF047857);
  static const _emerald900 = Color(0xFF064E3B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: complete ? _emerald50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: complete ? _emerald200 : ClusterPalette.slate200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: complete ? _emerald600 : ClusterPalette.slate400,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: _qtyText(
              'Separadas: ',
              quantity,
              complete ? _emerald700 : ClusterPalette.slate600,
              complete ? _emerald900 : ClusterPalette.slate900,
            ),
          ),
        ],
      ),
    );
  }
}
