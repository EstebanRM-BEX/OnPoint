import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/app_inspector/presentation/app_inspector_report.dart';

/// Diálogo con Resumen / Rutas / Blocs. Se abre con
/// `routeSettings: kAppInspectorRouteName` para no contarse a sí mismo.
class AppInspectorDialog extends StatefulWidget {
  const AppInspectorDialog({super.key});

  @override
  State<AppInspectorDialog> createState() => _AppInspectorDialogState();
}

class _AppInspectorDialogState extends State<AppInspectorDialog> {
  late AppInspectorReport _report = AppInspectorReport.capture();

  void _refresh() => setState(() => _report = AppInspectorReport.capture());

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _report.toText()));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Reporte copiado')));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: size.width,
        height: size.height * 0.75,
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: primaryColorApp,
              foregroundColor: Colors.white,
              title: const Text('Inspector', style: TextStyle(fontSize: 16)),
              actions: [
                IconButton(
                  tooltip: 'Actualizar',
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                ),
                IconButton(
                  tooltip: 'Copiar reporte',
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: _copy,
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Resumen'),
                  Tab(text: 'Rutas'),
                  Tab(text: 'Blocs'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _SummaryTab(report: _report),
                _RoutesTab(report: _report),
                _BlocsTab(report: _report),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final AppInspectorReport report;
  const _SummaryTab({required this.report});

  @override
  Widget build(BuildContext context) {
    final s = report.snapshot;
    final rows = <(String, String, bool)>[
      ('Widgets vivos', s.elements < 0 ? '-' : '${s.elements}', false),
      ('Memoria (RSS)', report.rssMb < 0 ? '-' : '${report.rssMb} MB', false),
      ('Blocs vivos', '${report.alive}', false),
      ('Blocs cerrados', '${report.closed}', false),
    ];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _RouteGroup(
          title: 'Pantallas apiladas',
          count: s.pages,
          warn: s.pages > 4,
          nodes: report.pageNodes,
        ),
        _RouteGroup(
          title: 'Diálogos / overlays',
          count: s.overlays,
          warn: s.overlays > 1,
          nodes: report.dialogNodes,
        ),
        for (final r in rows)
          ListTile(
            dense: true,
            title: Text(r.$1),
            trailing: Text(
              r.$2,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: r.$3 ? Colors.red : const Color(0xFF1E293B),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Tomado a las ${AppInspectorReport.hhmmss(report.takenAt)}. '
            'En rojo: posible acumulación. Toca pantallas o diálogos para ver '
            'cuáles son.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}

/// Fila del resumen con el conteo; al tocarla se despliega la lista de rutas
/// (nombre, qué widget muestran y cuándo se abrieron), de la base a la cima.
class _RouteGroup extends StatelessWidget {
  final String title;
  final int count;
  final bool warn;
  final List<MountNode> nodes;

  const _RouteGroup({
    required this.title,
    required this.count,
    required this.warn,
    required this.nodes,
  });

  @override
  Widget build(BuildContext context) {
    final countColor = warn ? Colors.red : const Color(0xFF1E293B);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        dense: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: countColor,
              ),
            ),
            const Icon(Icons.expand_more, size: 18),
          ],
        ),
        children: [
          if (nodes.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Ninguno',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ),
          for (var i = 0; i < nodes.length; i++)
            _RouteLine(index: i + 1, node: nodes[i]),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final int index;
  final MountNode node;

  const _RouteLine({required this.index, required this.node});

  @override
  Widget build(BuildContext context) {
    final content = AppInspectorReport.contentOf(node);
    final at = node.openedAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$index.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (content != null)
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF475569),
                    ),
                  ),
              ],
            ),
          ),
          if (at != null)
            Text(
              AppInspectorReport.hhmmss(at),
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }
}

class _TreeRow {
  const _TreeRow(this.node, this.depth, this.hasChildren);
  final MountNode node;
  final int depth;
  final bool hasChildren;
}

class _RoutesTab extends StatefulWidget {
  final AppInspectorReport report;
  const _RoutesTab({required this.report});

  @override
  State<_RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends State<_RoutesTab> {
  bool _onlyRelevant = true;

  /// Nodos de ruta contraídos. Al inicio: todas menos la cima.
  late Set<MountNode> _collapsed = _initialCollapsed();

  @override
  void didUpdateWidget(covariant _RoutesTab old) {
    super.didUpdateWidget(old);
    if (old.report != widget.report) _collapsed = _initialCollapsed();
  }

  /// Esqueleto: se ven los envoltorios desde GetMaterialApp y cada ruta hasta
  /// su `Scaffold` (pantalla) o su diálogo; lo de adentro queda contraído.
  Set<MountNode> _initialCollapsed() {
    final collapsed = <MountNode>{};
    final stop = RegExp(r'^(Scaffold|\w*Dialog|\w*BottomSheet)$');

    void walk(MountNode n, {required bool inRoute, required bool cut}) {
      var cutHere = cut;
      if (n.isSelf || n.label == 'ListenableBuilder') {
        collapsed.add(n);
      } else if (inRoute && !cut && n.relevant && stop.hasMatch(n.label)) {
        collapsed.add(n);
        cutHere = true;
      }
      for (final c in n.children) {
        walk(
          c,
          inRoute: inRoute || n.isRoute,
          // Una ruta anidada reinicia el corte.
          cut: c.isRoute ? false : cutHere,
        );
      }
    }

    final root = widget.report.root;
    if (root != null) walk(root, inRoute: false, cut: false);
    return collapsed;
  }

  bool _visible(MountNode n) => !_onlyRelevant || n.relevant;

  List<_TreeRow> _rows() {
    final rows = <_TreeRow>[];
    void walk(MountNode n, int depth) {
      final shown = _visible(n);
      final hasChildren = n.children.any(_hasVisible);
      if (shown) rows.add(_TreeRow(n, depth, hasChildren));
      if (shown && _collapsed.contains(n)) return;
      for (final c in n.children) {
        walk(c, shown ? depth + 1 : depth);
      }
    }

    final root = widget.report.root;
    if (root != null) walk(root, 0);
    return rows;
  }

  bool _hasVisible(MountNode n) => _visible(n) || n.children.any(_hasVisible);

  @override
  Widget build(BuildContext context) {
    if (widget.report.root == null) {
      return const Center(child: Text('Sin árbol'));
    }
    final rows = _rows();
    return Column(
      children: [
        SwitchListTile.adaptive(
          dense: true,
          title: const Text(
            'Solo widgets relevantes',
            style: TextStyle(fontSize: 12),
          ),
          subtitle: Text(
            '${widget.report.snapshot.pages} pantallas · '
            '${widget.report.snapshot.overlays} diálogos'
            '${widget.report.truncated ? ' · árbol cortado' : ''}',
            style: const TextStyle(fontSize: 11),
          ),
          value: _onlyRelevant,
          activeColor: primaryColorApp,
          onChanged: (v) => setState(() => _onlyRelevant = v),
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              // Ancho estimado de la fila más larga (fuente monoespaciada
              // de 12 px ≈ 7.3 px por carácter + sangría + iconos).
              var needed = 0.0;
              for (final r in rows) {
                final n = r.node;
                final label = n.isRoute ? '${n.label}  ·  pantalla' : n.label;
                final w =
                    8 +
                    r.depth * 14.0 +
                    16 +
                    (n.isRoute ? 18 : 0) +
                    label.length * 7.3 +
                    16;
                if (w > needed) needed = w;
              }
              final width = needed > box.maxWidth ? needed : box.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  height: box.maxHeight,
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, i) => _TreeRowTile(
                      row: rows[i],
                      collapsed: _collapsed.contains(rows[i].node),
                      onToggle: () => setState(() {
                        final n = rows[i].node;
                        _collapsed.contains(n)
                            ? _collapsed.remove(n)
                            : _collapsed.add(n);
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TreeRowTile extends StatelessWidget {
  final _TreeRow row;
  final bool collapsed;
  final VoidCallback onToggle;

  const _TreeRowTile({
    required this.row,
    required this.collapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final n = row.node;
    final isPage = n.routeKind == RouteKind.page;
    final color = n.isRoute
        ? (isPage ? primaryColorApp : Colors.orange)
        : n.relevant
        ? const Color(0xFF1E293B)
        : const Color(0xFF94A3B8);
    return InkWell(
      onTap: row.hasChildren ? onToggle : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8 + row.depth * 14.0, 3, 8, 3),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              child: row.hasChildren
                  ? Icon(
                      collapsed ? Icons.chevron_right : Icons.expand_more,
                      size: 16,
                      color: const Color(0xFF64748B),
                    )
                  : null,
            ),
            if (n.isRoute) ...[
              Icon(
                isPage ? Icons.smartphone : Icons.chat_bubble_outline,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              n.isRoute
                  ? '${n.label}  ·  ${isPage ? 'pantalla' : 'diálogo'}'
                  : n.label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: n.relevant ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlocsTab extends StatelessWidget {
  final AppInspectorReport report;
  const _BlocsTab({required this.report});

  @override
  Widget build(BuildContext context) {
    if (report.blocs.isEmpty) {
      return const Center(child: Text('Sin blocs'));
    }
    return ListView.separated(
      itemCount: report.blocs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final b = report.blocs[i];
        final color = b.isClosed ? Colors.grey : Colors.green;
        return ListTile(
          dense: true,
          leading: Icon(Icons.circle, color: color, size: 12),
          title: Text(b.name, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            '${b.isClosed ? 'Cerrado' : 'Vivo'} · estado: ${b.lastState}\n'
            'evento: ${b.lastEvent} · cambios: ${b.changes}',
            style: const TextStyle(fontSize: 11),
          ),
          isThreeLine: true,
        );
      },
    );
  }
}
