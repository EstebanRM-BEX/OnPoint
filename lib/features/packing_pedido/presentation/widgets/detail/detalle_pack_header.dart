import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/onpoint_header_surface.dart';

/// Pestaña con contador para el encabezado del detalle.
class TabContadorPack {
  final String texto;
  final IconData icono;
  final int contador;
  final Color color;

  const TabContadorPack(this.texto, this.icono, this.contador, this.color);
}

/// Barra superior del detalle: volver, nombre del pedido, imprimir y
/// pestañas con contadores.
class DetallePackHeader extends StatelessWidget {
  final String titulo;
  final VoidCallback onBack;
  final VoidCallback? onImprimir;
  final TabController controller;
  final List<TabContadorPack> tabs;

  const DetallePackHeader({
    super.key,
    required this.titulo,
    required this.onBack,
    required this.controller,
    required this.tabs,
    this.onImprimir,
  });

  @override
  Widget build(BuildContext context) {
    return OnPointHeaderSurface(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: white),
                  onPressed: onBack,
                ),
                Expanded(
                  child: Text(
                    titulo,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.print, color: white),
                  onPressed: onImprimir,
                ),
              ],
            ),
          ),
          TabBar(
            controller: controller,
            isScrollable: false,
            indicatorColor: white,
            indicatorWeight: 3,
            labelPadding: EdgeInsets.zero,
            labelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            labelColor: white,
            unselectedLabelColor: white.withValues(alpha: 0.75),
            tabs: [
              for (final t in tabs)
                Tab(
                  height: 56,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: t.contador >= 0,
                        label: Text('${t.contador}'),
                        backgroundColor: t.color,
                        child: Icon(t.icono, color: white, size: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(t.texto, maxLines: 1),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
