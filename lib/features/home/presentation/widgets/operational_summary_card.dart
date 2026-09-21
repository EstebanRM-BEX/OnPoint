import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Conteo de una tabla local con su estado de carga.
class SummaryMetric {
  final int count;
  final bool loading;
  const SummaryMetric({required this.count, this.loading = false});
}

/// "Resumen operativo": conteos de datos descargados en la PDA. Colapsable.
///
/// Recibe los valores ya resueltos: los BlocBuilder viven en la página, así
/// este widget es puro y fácil de probar.
class OperationalSummaryCard extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final SummaryMetric terceros;
  final SummaryMetric productos;
  final SummaryMetric ubicaciones;
  final SummaryMetric novedades;
  final SummaryMetric almacenes;

  const OperationalSummaryCard({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.terceros,
    required this.productos,
    required this.ubicaciones,
    required this.novedades,
    required this.almacenes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0F2FE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14075985),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _Header(expanded: expanded, onToggle: onToggle, almacenes: almacenes),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? _Body(this)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final SummaryMetric almacenes;

  const _Header({
    required this.expanded,
    required this.onToggle,
    required this.almacenes,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0EA5E9), primaryColorApp],
                ),
              ),
              child: const Icon(Icons.insights, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RESUMEN OPERATIVO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Datos descargados en la PDA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            _Pill(
              text:
                  '${almacenes.count} '
                  '${almacenes.count == 1 ? 'Bodega' : 'Bodegas'}',
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.expand_more,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final OperationalSummaryCard card;
  const _Body(this.card);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'TERCEROS',
                  icon: Icons.group_outlined,
                  metric: card.terceros,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'PRODUCTOS',
                  icon: Icons.inventory_2_outlined,
                  metric: card.productos,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'UBICACIONES',
                  icon: Icons.grid_view,
                  metric: card.ubicaciones,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HighlightTile(
                  label: 'NOVEDADES',
                  caption: 'Registradas',
                  icon: Icons.notification_important_outlined,
                  color: primaryColorApp,
                  metric: card.novedades,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HighlightTile(
                  label: 'BODEGAS',
                  caption: 'Permitidas',
                  icon: Icons.warehouse_outlined,
                  color: primaryColorApp,
                  metric: card.almacenes,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _format(int n) {
  // Separador de miles sin depender de intl: 23530 → 23.530
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

class _MetricTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final SummaryMetric metric;

  const _MetricTile({
    required this.label,
    required this.icon,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Icon(icon, size: 14, color: primaryColorApp),
            ],
          ),
          const SizedBox(height: 6),
          metric.loading
              ? const _LoadingValue()
              : Text(
                  _format(metric.count),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final SummaryMetric metric;

  const _HighlightTile({
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Color.lerp(color, Colors.black, 0.4),
                  ),
                ),
                Text(caption, style: TextStyle(fontSize: 10, color: color)),
              ],
            ),
          ),
          metric.loading
              ? const _LoadingValue(size: 14)
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _format(metric.count),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingValue extends StatelessWidget {
  final double size;
  const _LoadingValue({this.size = 17});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        color: primaryColorApp,
      ),
    );
  }
}
