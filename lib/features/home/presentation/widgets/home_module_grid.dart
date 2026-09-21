import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Módulo operativo del home.
class HomeModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const HomeModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

/// Rejilla paginada de módulos (3 columnas, hasta 9 por página) con puntos
/// indicadores.
class HomeModuleGrid extends StatefulWidget {
  final List<List<HomeModule>> pages;

  const HomeModuleGrid({super.key, required this.pages});

  static const double tileHeight = 104;
  static const double gap = 10;
  static const int columns = 3;

  @override
  State<HomeModuleGrid> createState() => _HomeModuleGridState();
}

class _HomeModuleGridState extends State<HomeModuleGrid> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _total => widget.pages.fold(0, (sum, p) => sum + p.length);

  @override
  Widget build(BuildContext context) {
    // La altura la fija la página con más filas: el PageView necesita un
    // alto finito y así no hay saltos de layout al deslizar.
    final maxRows = widget.pages
        .map((p) => (p.length / HomeModuleGrid.columns).ceil())
        .fold(0, (a, b) => a > b ? a : b);
    final height =
        maxRows * HomeModuleGrid.tileHeight +
        (maxRows - 1) * HomeModuleGrid.gap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'MÓDULOS PRINCIPALES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Text(
                '$_total Disponibles',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: primaryColorApp,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.pages[i].length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: HomeModuleGrid.columns,
                mainAxisSpacing: HomeModuleGrid.gap,
                crossAxisSpacing: HomeModuleGrid.gap,
                mainAxisExtent: HomeModuleGrid.tileHeight,
              ),
              itemBuilder: (_, j) => _ModuleTile(module: widget.pages[i][j]),
            ),
          ),
        ),
        if (widget.pages.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _page == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _page == i
                        ? primaryColorApp
                        : const Color(0xFFCBD5E1),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final HomeModule module;
  const _ModuleTile({required this.module});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: module.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColorApp.withOpacity(0.06),
                      primaryColorApp.withOpacity(0.14),
                    ],
                  ),
                ),
                child: Icon(module.icon, size: 24, color: primaryColorApp),
              ),
              const SizedBox(height: 6),
              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                module.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
