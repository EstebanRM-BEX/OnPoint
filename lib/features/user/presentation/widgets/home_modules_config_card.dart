import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/home/presentation/models/home_module_catalog.dart';
import 'package:wms_app/features/home/presentation/widgets/home_module_grid.dart';
import 'config_card.dart';

/// Tarjeta "Módulos del home": vista previa del home con los mismos tiles.
/// Mantener presionado y soltar sobre otra posición para mover; soltar en
/// "Ocultos" (o tocar el ojo) para ocultar. Se guarda por dispositivo en cada
/// cambio.
class HomeModulesConfigCard extends StatefulWidget {
  const HomeModulesConfigCard({super.key});

  @override
  State<HomeModulesConfigCard> createState() => _HomeModulesConfigCardState();
}

class _HomeModulesConfigCardState extends State<HomeModulesConfigCard> {
  HomeModulesLayout? _layout;

  @override
  void initState() {
    super.initState();
    HomeModulesPrefs.load().then((layout) {
      if (mounted) setState(() => _layout = layout);
    });
  }

  void _update(HomeModulesLayout layout) {
    setState(() => _layout = layout);
    HomeModulesPrefs.save(layout);
  }

  void _moveTo(HomeModuleId id, int index) =>
      _update(_layout!.moveTo(id, index));

  void _hide(HomeModuleId id) {
    final layout = _layout!;
    if (!layout.isVisible(id)) return;
    if (!layout.canHide(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debe haber al menos ${HomeModulesLayout.minVisible} '
            'módulos visibles en el home',
          ),
        ),
      );
      return;
    }
    _update(layout.hide(id));
  }

  Future<void> _restoreDefaults() async {
    await HomeModulesPrefs.reset();
    if (!mounted) return;
    setState(() => _layout = HomeModulesLayout.defaults);
  }

  @override
  Widget build(BuildContext context) {
    final layout = _layout;
    return ConfigCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.dashboard_customize_outlined,
                size: 18,
                color: primaryColorApp,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MÓDULOS DEL HOME',
                  style: ConfigText.sectionTitle.copyWith(
                    color: primaryColorApp,
                  ),
                ),
              ),
              if (layout != null)
                Text(
                  '${layout.visible.length}/${layout.order.length} visibles',
                  style: ConfigText.label,
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Mantenga presionado un módulo y suéltelo sobre la posición '
            'deseada. Mínimo ${HomeModulesLayout.minVisible} visibles.',
            style: ConfigText.label,
          ),
          const SizedBox(height: 12),
          if (layout == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            LayoutBuilder(
              builder: (_, constraints) =>
                  _buildPreview(layout, _tileWidth(constraints.maxWidth)),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: layout == null ? null : _restoreDefaults,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Restaurar por defecto'),
              style: TextButton.styleFrom(foregroundColor: primaryColorApp),
            ),
          ),
        ],
      ),
    );
  }

  double _tileWidth(double maxWidth) =>
      (maxWidth - HomeModuleGrid.gap * (HomeModuleGrid.columns - 1)) /
      HomeModuleGrid.columns;

  Widget _buildPreview(HomeModulesLayout layout, double tileWidth) {
    final visible = layout.visible;
    final hidden = layout.hiddenInOrder;
    const perPage = HomeModuleGrid.modulesPerPage;
    final pageCount = (visible.length / perPage).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var p = 0; p < pageCount; p++) ...[
          if (pageCount > 1) _Caption('PÁGINA ${p + 1}'),
          _Grid(
            children: [
              for (
                var i = p * perPage;
                i < visible.length && i < (p + 1) * perPage;
                i++
              )
                _VisibleSlot(
                  id: visible[i],
                  position: i + 1,
                  tileWidth: tileWidth,
                  onDrop: (dragged) => _moveTo(dragged, i),
                  onHide: () => _hide(visible[i]),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _HiddenZone(
          hidden: hidden,
          tileWidth: tileWidth,
          onDrop: _hide,
          onShow: (id) => _update(layout.show(id)),
        ),
      ],
    );
  }
}

/// Rejilla con la misma geometría que [HomeModuleGrid].
class _Grid extends StatelessWidget {
  final List<Widget> children;
  const _Grid({required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: HomeModuleGrid.columns,
        mainAxisSpacing: HomeModuleGrid.gap,
        crossAxisSpacing: HomeModuleGrid.gap,
        mainAxisExtent: HomeModuleGrid.tileHeight,
      ),
      children: children,
    );
  }
}

HomeModule _moduleOf(HomeModuleId id) =>
    HomeModule(title: id.title, subtitle: id.subtitle, icon: id.icon);

/// Tile arrastrable (long press para no pelear con el scroll de la página).
class _DraggableTile extends StatelessWidget {
  final HomeModuleId id;
  final double tileWidth;
  final Widget child;

  const _DraggableTile({
    required this.id,
    required this.tileWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<HomeModuleId>(
      data: id,
      onDragStarted: HapticFeedback.selectionClick,
      feedback: Material(
        color: Colors.transparent,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: tileWidth,
          height: HomeModuleGrid.tileHeight,
          child: HomeModuleTile(module: _moduleOf(id)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}

class _VisibleSlot extends StatelessWidget {
  final HomeModuleId id;
  final int position;
  final double tileWidth;
  final ValueChanged<HomeModuleId> onDrop;
  final VoidCallback onHide;

  const _VisibleSlot({
    required this.id,
    required this.position,
    required this.tileWidth,
    required this.onDrop,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<HomeModuleId>(
      onWillAcceptWithDetails: (d) => d.data != id,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (_, candidates, __) => _DraggableTile(
        id: id,
        tileWidth: tileWidth,
        child: Stack(
          children: [
            Positioned.fill(child: HomeModuleTile(module: _moduleOf(id))),
            Positioned(top: 6, left: 6, child: _PositionBadge(position)),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: onHide,
                visualDensity: VisualDensity.compact,
                tooltip: 'Ocultar',
                icon: const Icon(
                  Icons.visibility_off_outlined,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
            if (candidates.isNotEmpty)
              Positioned.fill(child: _DropHighlight()),
          ],
        ),
      ),
    );
  }
}

class _HiddenZone extends StatelessWidget {
  final List<HomeModuleId> hidden;
  final double tileWidth;
  final ValueChanged<HomeModuleId> onDrop;
  final ValueChanged<HomeModuleId> onShow;

  const _HiddenZone({
    required this.hidden,
    required this.tileWidth,
    required this.onDrop,
    required this.onShow,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<HomeModuleId>(
      onWillAcceptWithDetails: (d) => !hidden.contains(d.data),
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (_, candidates, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? primaryColorApp.withOpacity(0.06)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: candidates.isNotEmpty
                ? primaryColorApp
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Caption('OCULTOS'),
            if (hidden.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Suelte aquí un módulo para ocultarlo del home',
                  textAlign: TextAlign.center,
                  style: ConfigText.label,
                ),
              )
            else
              _Grid(
                children: [
                  for (final id in hidden)
                    _DraggableTile(
                      id: id,
                      tileWidth: tileWidth,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.45,
                              child: HomeModuleTile(
                                module: HomeModule(
                                  title: id.title,
                                  subtitle: id.subtitle,
                                  icon: id.icon,
                                  onTap: () => onShow(id),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: () => onShow(id),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Mostrar',
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 18,
                                color: primaryColorApp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final int position;
  const _PositionBadge(this.position);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: primaryColorApp,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$position',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DropHighlight extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: primaryColorApp.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColorApp, width: 2),
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;
  const _Caption(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(text, style: ConfigText.caption),
    );
  }
}
