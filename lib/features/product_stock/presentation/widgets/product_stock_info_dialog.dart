import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/product_stock/domain/entities/product_stock_info.dart';

// Paleta del diseño Stitch "OnPoint - Modal Detalle de Ubicaciones, Lotes y
// Vencimiento" (slate / emerald de Tailwind).
const _slate50 = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFE2E8F0);
const _slate300 = Color(0xFFCBD5E1);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate700 = Color(0xFF334155);
const _slate900 = Color(0xFF0F172A);
const _blue50 = Color(0xFFEFF6FF);
const _blue100 = Color(0xFFDBEAFE);
const _emerald50 = Color(0xFFECFDF5);
const _emerald100 = Color(0xFFD1FAE5);
const _emerald600 = Color(0xFF059669);
const _emerald800 = Color(0xFF065F46);
const _amber50 = Color(0xFFFFFBEB);
const _amber200 = Color(0xFFFDE68A);
const _amber700 = Color(0xFFB45309);
const _mono = 'monospace';

/// Bottom sheet con la info del producto y las ubicaciones donde está.
///
/// Con existencias lista ubicaciones + lotes; sin existencias muestra las
/// últimas ubicaciones del historial (o un aviso si no hay historial).
class ProductStockInfoDialog extends StatelessWidget {
  final ProductStockInfo info;

  const ProductStockInfoDialog({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _GrabHandle(),
          _Header(producto: info.producto),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info.tieneExistencias
                      ? _KpiSummary(info: info)
                      : _NoStockBanner(msg: info.msg),
                  const SizedBox(height: 16),
                  _LocationsSection(info: info),
                ],
              ),
            ),
          ),
          const _CloseFooter(),
        ],
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: _slate300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final StockProducto? producto;

  const _Header({required this.producto});

  @override
  Widget build(BuildContext context) {
    final referencia = producto?.referencia ?? '';
    final barcode = producto?.barcode ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _slate100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _blue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _blue100),
            ),
            child: Icon(Icons.inventory_2_outlined,
                color: primaryColorApp, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _blue50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PRODUCTO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: primaryColorApp,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  producto?.nombre ?? 'Producto',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _slate900,
                    height: 1.3,
                  ),
                ),
                if (referencia.isNotEmpty || barcode.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      if (referencia.isNotEmpty)
                        _CodeLabel(label: 'Ref:', value: referencia),
                      if (barcode.isNotEmpty)
                        _CodeLabel(
                          icon: Icons.view_week_outlined,
                          label: 'Barcode:',
                          value: barcode,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: _slate400, size: 22),
            visualDensity: VisualDensity.compact,
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

class _CodeLabel extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const _CodeLabel({this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: _slate400),
          const SizedBox(width: 4),
        ],
        Text(
          '$label ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _slate400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: _mono,
            color: _slate700,
          ),
        ),
      ],
    );
  }
}

class _KpiSummary extends StatelessWidget {
  final ProductStockInfo info;

  const _KpiSummary({required this.info});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'TOTAL',
            value: _qty(info.totalCantidad),
            caption: 'Unidades registradas',
            background: _blue50,
            border: _blue100,
            labelColor: _slate500,
            valueColor: primaryColorApp,
            captionColor: _slate400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            label: 'DISPONIBLE',
            value: _qty(info.totalDisponible),
            caption: 'Listas para despacho',
            background: _emerald50,
            border: _emerald100,
            labelColor: _emerald800,
            valueColor: _emerald600,
            captionColor: _emerald600,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color background;
  final Color border;
  final Color labelColor;
  final Color valueColor;
  final Color captionColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.background,
    required this.border,
    required this.labelColor,
    required this.valueColor,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: labelColor,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: captionColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoStockBanner extends StatelessWidget {
  final String msg;

  const _NoStockBanner({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amber50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _amber700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg.isNotEmpty ? msg : 'Producto sin existencias',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _amber700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationsSection extends StatelessWidget {
  final ProductStockInfo info;

  const _LocationsSection({required this.info});

  @override
  Widget build(BuildContext context) {
    final withStock = info.tieneExistencias;
    final count =
        withStock ? info.ubicaciones.length : info.ultimasUbicaciones.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              withStock ? 'Ubicaciones' : 'Últimas ubicaciones',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _slate900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: _slate100,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _slate200),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _slate700,
                ),
              ),
            ),
            const Spacer(),
            if (withStock && count > 0)
              const Text(
                'Disp. / Total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _slate400,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (count == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Sin historial de ubicaciones',
                style: TextStyle(fontSize: 13, color: _slate400),
              ),
            ),
          )
        else if (withStock)
          for (final u in info.ubicaciones) ...[
            _UbicacionCard(ubicacion: u),
            const SizedBox(height: 12),
          ]
        else
          for (final u in info.ultimasUbicaciones) ...[
            _UltimaUbicacionCard(ubicacion: u),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _UbicacionCard extends StatelessWidget {
  final StockUbicacion ubicacion;

  const _UbicacionCard({required this.ubicacion});

  @override
  Widget build(BuildContext context) {
    final disponible = ubicacion.disponible;
    return _CardFrame(
      title: _title(ubicacion.ubicacionEspecifica, ubicacion.ubicacionCompleta),
      subtitle: ubicacion.ubicacionCompleta,
      highlighted: disponible > 0,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _qty(disponible),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: disponible > 0 ? _emerald600 : _slate400,
            ),
          ),
          const Text(
            'disp',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _slate400,
            ),
          ),
        ],
      ),
      rows: [for (final lote in ubicacion.lotes) _LoteRow(lote: lote)],
    );
  }
}

class _LoteRow extends StatelessWidget {
  final StockLote lote;

  const _LoteRow({required this.lote});

  @override
  Widget build(BuildContext context) {
    final hasLote = lote.loteId != null;
    final disponible = lote.cantidadDisponible > 0;
    final vence = _formatDate(lote.fechaVencimiento);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                size: 16,
                color: hasLote ? primaryColorApp : _slate400,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasLote ? 'Lote: ${lote.lote}' : lote.lote,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasLote ? FontWeight.w600 : FontWeight.w500,
                    fontFamily: hasLote ? _mono : null,
                    color: hasLote ? primaryColorApp : _slate700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: disponible ? _emerald50 : _slate50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: disponible ? _emerald100 : _slate100,
                  ),
                ),
                child: Text(
                  'Disp: ${_qty(lote.cantidadDisponible)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: _mono,
                    fontWeight: disponible ? FontWeight.w700 : FontWeight.w500,
                    color: disponible ? _emerald600 : _slate500,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MonoStat(label: 'Cant:', value: _qty(lote.cantidad)),
                _MonoStat(label: 'Res:', value: _qty(lote.cantidadReservada)),
                if (vence != null) _VenceLabel(fecha: vence),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UltimaUbicacionCard extends StatelessWidget {
  final StockUltimaUbicacion ubicacion;

  const _UltimaUbicacionCard({required this.ubicacion});

  @override
  Widget build(BuildContext context) {
    final vence = _formatDate(ubicacion.fechaVencimiento);
    return _CardFrame(
      title: _title(ubicacion.ubicacionEspecifica, ubicacion.ubicacionCompleta),
      subtitle: ubicacion.ubicacionCompleta,
      highlighted: false,
      rows: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ubicacion.ultimoLote.isNotEmpty)
                _DetailLine(
                  icon: Icons.qr_code_2,
                  label: 'Último lote:',
                  value: ubicacion.ultimoLote,
                ),
              if (vence != null)
                _DetailLine(
                  icon: Icons.calendar_today_outlined,
                  label: 'Vence:',
                  value: vence,
                ),
              if (ubicacion.fechaMovimiento.isNotEmpty)
                _DetailLine(
                  icon: Icons.schedule,
                  label: 'Movimiento:',
                  value: ubicacion.fechaMovimiento,
                ),
              if (ubicacion.documento.isNotEmpty)
                _DetailLine(
                  icon: Icons.description_outlined,
                  label: 'Documento:',
                  value: ubicacion.documento,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool highlighted;
  final Widget? trailing;
  final List<Widget> rows;

  const _CardFrame({
    required this.title,
    required this.subtitle,
    required this.highlighted,
    this.trailing,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: highlighted ? _blue50 : _slate100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.location_on_outlined,
                    size: 18, color: primaryColorApp),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: _mono,
                        color: primaryColorApp,
                      ),
                    ),
                    if (subtitle.isNotEmpty && subtitle != title)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: _mono,
                          color: _slate400,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: _slate100),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: _slate100),
              rows[i],
            ],
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MonoStat extends StatelessWidget {
  final String label;
  final String value;

  const _MonoStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 11, fontFamily: _mono),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(color: _slate500)),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: _slate700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VenceLabel extends StatelessWidget {
  final String fecha;

  const _VenceLabel({required this.fecha});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_today_outlined, size: 12, color: _slate400),
        const SizedBox(width: 4),
        Text(
          'Vence: $fecha',
          style: const TextStyle(fontSize: 11, color: _slate400),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _slate400),
          const SizedBox(width: 6),
          Text(
            '$label ',
            style: const TextStyle(fontSize: 12, color: _slate400),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: _mono,
                fontWeight: FontWeight.w600,
                color: _slate700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseFooter extends StatelessWidget {
  const _CloseFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: white,
        border: Border(top: BorderSide(color: _slate100)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check, color: white, size: 18),
          label: const Text(
            'Cerrar',
            style: TextStyle(
              color: white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColorApp,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

String _title(String especifica, String completa) =>
    especifica.isNotEmpty ? especifica : completa;

/// 80.0 → "80", 12.5 → "12.5".
String _qty(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

/// "2027-03-15" → "15/03/2027". null si no hay fecha (no se muestra).
String? _formatDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value == 'false') return null;
  final parsed = DateTime.tryParse(value);
  return parsed != null ? DateFormat('dd/MM/yyyy').format(parsed) : value;
}
