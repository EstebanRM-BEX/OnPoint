import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';
import 'package:wms_app/features/picking_cluster/presentation/utils/pedidos_ready_to_validate.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/validate/validate_product_tile.dart';

/// Pedido del batch en forma de acordeón: cabecera con muelle, barcode y
/// avance de envío de sus productos; al expandir, sus productos.
///
/// Un pedido sin todos sus productos enviados al WMS se muestra bloqueado
/// (gris, botón Validar desactivado). [onValidate] null oculta el botón;
/// [isValidating] lo reemplaza por un indicador de carga.
class PedidoValidateCard extends StatefulWidget {
  final PedidoValidate pedido;
  final List<BatchProduct> products;
  final VoidCallback? onValidate;
  final bool isValidating;
  final ValueChanged<bool>? onExpansionChanged;

  const PedidoValidateCard({
    super.key,
    required this.pedido,
    required this.products,
    this.onValidate,
    this.isValidating = false,
    this.onExpansionChanged,
  });

  @override
  State<PedidoValidateCard> createState() => _PedidoValidateCardState();
}

class _PedidoValidateCardState extends State<PedidoValidateCard> {
  bool _expanded = false;

  bool get _isValidated => widget.pedido.isValidated ?? false;

  PedidoSendProgress get _progress =>
      pedidoSendProgress(widget.pedido.idPedido, widget.products);

  bool get _isBlocked => !_isValidated && !_progress.isComplete;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isBlocked ? ClusterPalette.slate100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded ? ClusterPalette.slate300 : ClusterPalette.slate200,
          width: _expanded ? 1.5 : 1,
        ),
        boxShadow: _expanded ? ClusterPalette.cardShadow : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _expanded = !_expanded);
                widget.onExpansionChanged?.call(_expanded);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildHeader(),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _expanded ? _buildProducts() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_isBlocked)
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: ClusterPalette.slate400,
                    ),
                  Text(
                    widget.pedido.namePedido ?? 'Sin Nombre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _isBlocked
                          ? ClusterPalette.slate500
                          : ClusterPalette.brand700,
                    ),
                  ),
                  if (_isValidated) const _CompletedBadge(),
                ],
              ),
              const SizedBox(height: 6),
              _InfoLine(
                icon: Icons.domain,
                label: 'Muelle:',
                value: widget.pedido.muelle ?? 'Sin muelle',
              ),
              const SizedBox(height: 4),
              _InfoLine(
                icon: Icons.qr_code_2,
                label: 'Barcode:',
                value: widget.pedido.barcodeMuelle ?? 'N/A',
                monospace: true,
              ),
              const SizedBox(height: 10),
              _SendProgressBar(progress: _progress, validated: _isValidated),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _expanded
                      ? ClusterPalette.slate100
                      : ClusterPalette.slate50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: _expanded
                      ? ClusterPalette.slate600
                      : ClusterPalette.slate400,
                ),
              ),
            ),
            if (!_isValidated && widget.isValidating) ...[
              const SizedBox(height: 14),
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ] else if (!_isValidated && widget.onValidate != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: _isBlocked ? null : widget.onValidate,
                  icon: Icon(
                    _isBlocked ? Icons.lock_outline : Icons.check,
                    size: 14,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClusterPalette.brand600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ClusterPalette.slate200,
                    disabledForegroundColor: ClusterPalette.slate400,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: const Text(
                    'Validar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildProducts() {
    final products = widget.products;
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Text(
          'Sin productos para este pedido',
          style: TextStyle(fontSize: 12, color: ClusterPalette.slate400),
        ),
      );
    }
    final scrollable = products.length > 3;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ClusterPalette.slate100)),
      ),
      // Tope de altura para no construir cientos de items de una vez.
      constraints: BoxConstraints(
        maxHeight: scrollable
            ? MediaQuery.of(context).size.height * 0.6
            : double.infinity,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: scrollable
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) =>
            ValidateProductTile(product: products[index]),
      ),
    );
  }
}

/// Barra de avance: productos del pedido enviados al WMS sobre el total.
class _SendProgressBar extends StatelessWidget {
  final PedidoSendProgress progress;
  final bool validated;

  const _SendProgressBar({required this.progress, required this.validated});

  static const _emerald = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final complete = validated || progress.isComplete;
    final color = complete ? _emerald : ClusterPalette.amber500;
    final percent = (validated ? 1.0 : progress.ratio) * 100;

    final String caption;
    if (validated) {
      caption = 'Pedido validado';
    } else if (progress.total == 0) {
      caption = 'Sin productos en este batch';
    } else if (progress.isComplete) {
      caption = 'Listo para validar';
    } else {
      caption =
          'Faltan ${progress.missing} de ${progress.total} producto(s) por enviar';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: complete
                      ? const Color(0xFF047857)
                      : ClusterPalette.slate500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: complete
                    ? const Color(0xFF047857)
                    : ClusterPalette.slate600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 6,
            color: color,
            backgroundColor: ClusterPalette.slate200,
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: ClusterPalette.slate400),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: ClusterPalette.slate400,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          flex: 3,
          child: monospace
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: ClusterPalette.slate100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ClusterPalette.slate200),
                  ),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: ClusterPalette.slate700,
                    ),
                  ),
                )
              : Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ClusterPalette.slate800,
                  ),
                ),
        ),
      ],
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Validado',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF065F46),
        ),
      ),
    );
  }
}
