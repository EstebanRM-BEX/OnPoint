import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/confirm_delete_dialog.dart';
import 'package:wms_app/src/presentation/views/info_rapida/data/recent_queries_store.dart';

/// "Últimas consultas": historial local de Información Rápida. Tocar una
/// entrada la vuelve a consultar con los mismos parámetros.
///
/// Se carga al montarse: la pantalla se recrea al volver de un detalle
/// (pushReplacement), así que siempre muestra el historial actualizado.
class RecentQueriesCard extends StatefulWidget {
  final ValueChanged<RecentQuery> onSelect;

  const RecentQueriesCard({super.key, required this.onSelect});

  @override
  State<RecentQueriesCard> createState() => _RecentQueriesCardState();
}

class _RecentQueriesCardState extends State<RecentQueriesCard> {
  List<RecentQuery> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await RecentQueriesStore.instance.getAll();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _clear() async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Limpiar consultas',
      message:
          'Se eliminará el historial de últimas consultas de esta '
          'terminal.',
      confirmLabel: 'Limpiar',
    );
    if (!confirmed) return;
    await RecentQueriesStore.instance.clear();
    if (mounted) setState(() => _items = const []);
  }

  @override
  Widget build(BuildContext context) {
    // Sin historial no se muestra nada: la pantalla queda como antes.
    if (_items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'ÚLTIMAS CONSULTAS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 8),
              _Badge('${_items.length}'),
              const Spacer(),
              TextButton(
                onPressed: _clear,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Limpiar',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Divider(height: 12, color: Color(0xFFF1F5F9)),
          for (final item in _items) ...[
            const SizedBox(height: 8),
            _RecentQueryTile(item: item, onTap: () => widget.onSelect(item)),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: primaryColorApp.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: primaryColorApp.withOpacity(0.15)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: primaryColorApp,
        ),
      ),
    );
  }
}

class _RecentQueryTile extends StatelessWidget {
  final RecentQuery item;
  final VoidCallback onTap;

  const _RecentQueryTile({required this.item, required this.onTap});

  (IconData, Color) get _visual => switch (item.type) {
    'product' => (Icons.inventory_2_outlined, primaryColorApp),
    'ubicacion' => (Icons.location_on_outlined, const Color(0xFF047857)),
    'paquete' => (Icons.archive_outlined, const Color(0xFFB45309)),
    _ => (Icons.qr_code, const Color(0xFF475569)),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual;
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (item.badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
