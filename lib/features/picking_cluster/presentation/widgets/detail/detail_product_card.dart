import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';

enum _ItemStatus { complete, inProgress, separated, pending }

/// Ítem del detalle de batch. Los callbacks nulos ocultan su acción:
/// [onEdit] (ajustar cantidad), [onStart] (ir a separar este producto),
/// [onSync] (reenviar pendientes al WMS).
class DetailProductCard extends StatelessWidget {
  final BatchProduct product;
  final bool showOriginLocation;
  final String? separationTime;
  final VoidCallback onViewImage;
  final VoidCallback onPrint;
  final VoidCallback onPendingInfo;
  final VoidCallback? onEdit;
  final VoidCallback? onStart;
  final VoidCallback? onSync;

  /// Pedido al que pertenece el producto (nombre y muelle de despacho).
  final String? pedidoName;
  final String? pedidoMuelle;
  final bool pedidoValidated;

  const DetailProductCard({
    super.key,
    required this.product,
    required this.showOriginLocation,
    required this.onViewImage,
    required this.onPrint,
    required this.onPendingInfo,
    this.separationTime,
    this.onEdit,
    this.onStart,
    this.onSync,
    this.pedidoName,
    this.pedidoMuelle,
    this.pedidoValidated = false,
  });

  static num toNum(dynamic value) =>
      value is num ? value : num.tryParse('${value ?? ''}') ?? 0;

  static final _codePrefix = RegExp(r'^(\[[^\]]+\])\s*(.*)$');

  _ItemStatus get _status {
    if (product.quantitySeparate != null &&
        toNum(product.quantity) == toNum(product.quantitySeparate)) {
      return _ItemStatus.complete;
    }
    if (product.isSelected == 1) return _ItemStatus.inProgress;
    if (product.isSeparate == 1) return _ItemStatus.separated;
    return _ItemStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    final style = _StatusStyle.of(_status);
    return Container(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: style.strip),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitle(style),
                if (pedidoName != null && pedidoName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _PedidoTag(
                    name: pedidoName!,
                    muelle: pedidoMuelle,
                    validated: pedidoValidated,
                  ),
                ],
                const SizedBox(height: 10),
                _buildBarcode(style),
                const SizedBox(height: 10),
                _buildDetails(style),
                const SizedBox(height: 10),
                Divider(height: 1, color: style.border),
                const SizedBox(height: 10),
                _buildQuantities(style),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(_StatusStyle style) {
    final raw = '${product.productId ?? ''}';
    final match = _codePrefix.firstMatch(raw);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: style.title,
              ),
              children: match == null
                  ? [TextSpan(text: raw)]
                  : [
                      TextSpan(
                        text: '${match.group(1)} ',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: style.code,
                        ),
                      ),
                      TextSpan(text: match.group(2)),
                    ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _Chip(label: style.label, fg: style.badgeFg, bg: style.badgeBg),
        if (onEdit != null) ...[
          const SizedBox(width: 6),
          _IconAction(
            icon: Icons.edit_outlined,
            tooltip: 'Ajustar cantidad',
            color: ClusterPalette.brand600,
            background: Colors.white,
            onTap: onEdit!,
          ),
        ],
      ],
    );
  }

  Widget _buildBarcode(_StatusStyle style) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.border),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/barcode.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              ClusterPalette.slate500,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${product.barcode ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: ClusterPalette.slate800,
              ),
            ),
          ),
          if (onStart != null)
            TextButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_circle_fill, size: 18),
              label: const Text('Separar'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF059669),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails(_StatusStyle style) {
    final origin = '${product.origin ?? ''}';
    final lot = product.lotId;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.image_outlined,
                size: 16,
                color: ClusterPalette.brand600,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Imagen del producto:', style: _labelStyle),
              ),
              _OutlinedAction(
                icon: Icons.visibility_outlined,
                label: 'Ver foto',
                onTap: onViewImage,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (showOriginLocation)
            _DetailRow(
              icon: Icons.location_on,
              iconColor: ClusterPalette.brand600,
              label: 'Desde:',
              value: '${product.locationId ?? ''}',
              monospace: true,
              trailing: product.isPending == 1
                  ? _IconAction(
                      tooltip: 'Producto pendiente',
                      color: const Color(0xFFB45309),
                      background: const Color(0xFFFEF3C7),
                      onTap: onPendingInfo,
                      child: SvgPicture.asset(
                        'assets/icons/list_final.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFB45309),
                          BlendMode.srcIn,
                        ),
                      ),
                    )
                  : null,
            ),
          _DetailRow(
            icon: Icons.arrow_forward,
            iconColor: ClusterPalette.brand600,
            label: 'A:',
            value: '${product.locationDestId ?? ''}',
            valueColor: ClusterPalette.brand700,
            monospace: true,
          ),
          if (origin.isNotEmpty)
            _DetailRow(
              icon: Icons.description_outlined,
              label: 'Doc. origen:',
              value: origin,
              monospace: true,
            ),
          _DetailRow(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFF59E0B),
            label: 'Prioridad:',
            value: '${product.rimovalPriority ?? ''}',
          ),
          _buildExpiry(),
          if (lot != null && lot != '' && lot != false)
            _DetailRow(
              icon: Icons.bookmarks_outlined,
              label: 'Lote:',
              value: '$lot',
              monospace: true,
            ),
          const SizedBox(height: 4),
          Divider(height: 1, color: style.border.withOpacity(0.6)),
          const SizedBox(height: 8),
          _buildWmsRow(),
        ],
      ),
    );
  }

  Widget _buildExpiry() {
    final date = DateTime.tryParse('${product.expireDate ?? ''}');
    if (date == null) {
      return const _DetailRow(
        icon: Icons.calendar_today_outlined,
        label: 'Fecha caducidad:',
        value: 'Sin expiración',
        valueColor: Color(0xFFE11D48),
      );
    }
    final now = DateTime.now();
    final daysLeft = date.difference(now).inDays;
    final color = date.isBefore(now)
        ? const Color(0xFFDC2626)
        : daysLeft <= 30
        ? const Color(0xFFEA580C)
        : ClusterPalette.slate800;
    return _DetailRow(
      icon: Icons.calendar_today_outlined,
      label: 'Fecha caducidad:',
      value:
          '${date.toString().split(' ').first} '
          '(${daysLeft > 0 ? '$daysLeft días' : 'Vencido'})',
      valueColor: color,
    );
  }

  Widget _buildWmsRow() {
    final Widget status;
    if (product.isSendOdoo == 0) {
      status = const _Chip(
        icon: Icons.wifi_off,
        label: 'Pendiente de envío',
        fg: Color(0xFF9A3412),
        bg: Color(0xFFFFEDD5),
      );
    } else if (product.isSendOdoo == null) {
      status = const _Chip(
        label: 'Sin enviar',
        fg: ClusterPalette.brand700,
        bg: ClusterPalette.brand50,
      );
    } else {
      status = const _Chip(
        label: 'Enviado',
        fg: Color(0xFF065F46),
        bg: Color(0xFFD1FAE5),
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 16,
              color: Color(0xFF059669),
            ),
            const SizedBox(width: 6),
            const Text('WMS:', style: _labelStyle),
            const SizedBox(width: 6),
            Flexible(child: status),
          ],
        ),
        if (separationTime != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule,
                size: 15,
                color: ClusterPalette.slate400,
              ),
              const SizedBox(width: 4),
              Text(
                separationTime!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: ClusterPalette.slate600,
                ),
              ),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onSync != null) ...[
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClusterPalette.brand600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Enviar', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            _IconAction(
              icon: Icons.print_outlined,
              tooltip: 'Imprimir etiqueta',
              color: ClusterPalette.brand700,
              background: ClusterPalette.brand50,
              onTap: onPrint,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantities(_StatusStyle style) {
    final qty = toNum(product.quantity);
    final separated = toNum(product.quantitySeparate);
    final observation = product.observation ?? '';
    final showObservation =
        product.quantitySeparate == null || qty != separated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    text: '+ Unidades: ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ClusterPalette.slate700,
                    ),
                    children: [
                      TextSpan(
                        text: _formatQty(qty),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: ClusterPalette.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: 'U. Medida: ',
                    style: const TextStyle(
                      fontSize: 11,
                      color: ClusterPalette.slate500,
                    ),
                    children: [
                      TextSpan(
                        text: (product.unidades ?? '').toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ClusterPalette.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: style.qtyBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 16, color: style.qtyFg),
                  const SizedBox(width: 4),
                  Text(
                    'Separadas: ${_formatQty(separated)}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: style.qtyFg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showObservation) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                size: 15,
                color: ClusterPalette.slate400,
              ),
              const SizedBox(width: 6),
              const Text('Novedad: ', style: _labelStyle),
              Expanded(
                child: Text(
                  observation.isEmpty ? 'Sin novedad' : observation,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: ClusterPalette.slate700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Hasta 4 decimales, sin ceros sobrantes (12.0 → 12.0, 1.50 → 1.5).
  static String _formatQty(num value) =>
      double.parse(value.toDouble().toStringAsFixed(4)).toString();
}

const _labelStyle = TextStyle(fontSize: 12, color: ClusterPalette.slate500);

class _StatusStyle {
  final String label;
  final Color strip;
  final Color background;
  final Color border;
  final Color title;
  final Color code;
  final Color badgeFg;
  final Color badgeBg;
  final Color qtyFg;
  final Color qtyBg;

  const _StatusStyle({
    required this.label,
    required this.strip,
    required this.background,
    required this.border,
    required this.title,
    required this.code,
    required this.badgeFg,
    required this.badgeBg,
    required this.qtyFg,
    required this.qtyBg,
  });

  static const _complete = _StatusStyle(
    label: 'COMPLETO',
    strip: Color(0xFF10B981),
    background: Color(0xFFF3FBF7),
    border: Color(0xFFA7F3D0),
    title: Color(0xFF022C22),
    code: Color(0xFF065F46),
    badgeFg: Color(0xFF065F46),
    badgeBg: Color(0xFFD1FAE5),
    qtyFg: Colors.white,
    qtyBg: Color(0xFF059669),
  );

  static const _inProgress = _StatusStyle(
    label: 'EN CURSO',
    strip: ClusterPalette.brand500,
    background: ClusterPalette.brand50,
    border: Color(0xFFBAE0FD),
    title: ClusterPalette.slate900,
    code: ClusterPalette.brand700,
    badgeFg: ClusterPalette.brand700,
    badgeBg: ClusterPalette.brand100,
    qtyFg: Colors.white,
    qtyBg: ClusterPalette.brand600,
  );

  static const _separated = _StatusStyle(
    label: 'SEPARADO',
    strip: Color(0xFF34D399),
    background: Color(0xFFF3FBF7),
    border: Color(0xFFA7F3D0),
    title: Color(0xFF022C22),
    code: Color(0xFF065F46),
    badgeFg: Color(0xFF065F46),
    badgeBg: Color(0xFFD1FAE5),
    qtyFg: Color(0xFF92400E),
    qtyBg: Color(0xFFFEF3C7),
  );

  static const _pending = _StatusStyle(
    label: 'PENDIENTE',
    strip: Color(0xFFFBBF24),
    background: Colors.white,
    border: ClusterPalette.slate200,
    title: ClusterPalette.slate800,
    code: ClusterPalette.slate500,
    badgeFg: Color(0xFF92400E),
    badgeBg: Color(0xFFFEF3C7),
    qtyFg: ClusterPalette.slate700,
    qtyBg: ClusterPalette.slate100,
  );

  static _StatusStyle of(_ItemStatus status) => switch (status) {
    _ItemStatus.complete => _complete,
    _ItemStatus.inProgress => _inProgress,
    _ItemStatus.separated => _separated,
    _ItemStatus.pending => _pending,
  };
}

class _PedidoTag extends StatelessWidget {
  final String name;
  final String? muelle;
  final bool validated;

  const _PedidoTag({required this.name, this.muelle, this.validated = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ClusterPalette.brand50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ClusterPalette.brand100),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 16,
            color: ClusterPalette.brand600,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Pedido ',
                style: const TextStyle(
                  fontSize: 12,
                  color: ClusterPalette.slate500,
                ),
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ClusterPalette.brand700,
                    ),
                  ),
                  if (muelle != null && muelle!.isNotEmpty)
                    TextSpan(text: '  ·  $muelle'),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (validated) ...[
            const SizedBox(width: 6),
            const _Chip(
              label: 'VALIDADO',
              fg: Color(0xFF065F46),
              bg: Color(0xFFD1FAE5),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final bool monospace;
  final Widget? trailing;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = ClusterPalette.slate400,
    this.valueColor = ClusterPalette.slate800,
    this.monospace = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: _labelStyle),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: monospace ? 'monospace' : null,
                color: valueColor,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.fg,
    required this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final String tooltip;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _IconAction({
    this.icon,
    this.child,
    required this.tooltip,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 34,
            child: Center(child: child ?? Icon(icon, size: 18, color: color)),
          ),
        ),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlinedAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClusterPalette.brand50,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ClusterPalette.brand100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: ClusterPalette.brand600),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ClusterPalette.brand600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
