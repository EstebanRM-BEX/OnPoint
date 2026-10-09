import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/list/packing_pedido_list_bloc.dart';

/// Menú "⋮" de la lista: orden y filtros por responsable y propietario.
class OrdenPedidosPackMenu extends StatelessWidget {
  final OrdenPedidosPack orden;
  final bool ascendente;
  final String? propietario;
  final bool soloMios;
  final void Function(OrdenPedidosPack orden, bool ascendente) onOrden;
  final VoidCallback onFiltrarPropietario;
  final VoidCallback onSoloMios;

  const OrdenPedidosPackMenu({
    super.key,
    required this.orden,
    required this.ascendente,
    required this.propietario,
    required this.soloMios,
    required this.onOrden,
    required this.onFiltrarPropietario,
    required this.onSoloMios,
  });

  static const _valorPropietario = -1;
  static const _valorSoloMios = -2;

  static const _opciones = <(String, OrdenPedidosPack, bool, String, IconData)>[
    (
      'PRIORIDAD',
      OrdenPedidosPack.prioridad,
      false,
      'Alta primero',
      Icons.warning,
    ),
    (
      '',
      OrdenPedidosPack.prioridad,
      true,
      'Normal primero',
      Icons.low_priority,
    ),
    (
      'FECHA',
      OrdenPedidosPack.fecha,
      false,
      'Más recientes',
      Icons.arrow_downward,
    ),
    ('', OrdenPedidosPack.fecha, true, 'Más antiguos', Icons.arrow_upward),
    ('NOMBRE', OrdenPedidosPack.nombre, true, 'A → Z', Icons.sort_by_alpha),
    ('', OrdenPedidosPack.nombre, false, 'Z → A', Icons.sort_by_alpha),
    (
      'BACKORDER',
      OrdenPedidosPack.backorder,
      false,
      'Con backorder primero',
      Icons.file_copy,
    ),
    (
      '',
      OrdenPedidosPack.backorder,
      true,
      'Sin backorder primero',
      Icons.file_copy_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: white),
      onSelected: (i) {
        if (i == _valorSoloMios) return onSoloMios();
        if (i == _valorPropietario) return onFiltrarPropietario();
        final o = _opciones[i];
        onOrden(o.$2, o.$3);
      },
      itemBuilder: (_) {
        final items = <PopupMenuEntry<int>>[];
        for (var i = 0; i < _opciones.length; i++) {
          final (seccion, ord, asc, texto, icono) = _opciones[i];
          if (seccion.isNotEmpty) {
            if (items.isNotEmpty) items.add(const PopupMenuDivider());
            items.add(_titulo(seccion));
          }
          final activo = ord == orden && asc == ascendente;
          items.add(
            PopupMenuItem<int>(
              value: i,
              height: 40,
              child: Row(
                children: [
                  Icon(
                    icono,
                    size: 16,
                    color: activo ? primaryColorApp : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    texto,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                      color: activo ? primaryColorApp : black,
                    ),
                  ),
                  if (activo) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 15, color: primaryColorApp),
                  ],
                ],
              ),
            ),
          );
        }
        items
          ..add(const PopupMenuDivider())
          ..add(_titulo('RESPONSABLE'))
          ..add(
            PopupMenuItem<int>(
              value: _valorSoloMios,
              height: 40,
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: soloMios ? primaryColorApp : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mis pedidos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: soloMios
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: soloMios ? primaryColorApp : black,
                    ),
                  ),
                  if (soloMios) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 15, color: primaryColorApp),
                  ],
                ],
              ),
            ),
          )
          ..add(const PopupMenuDivider())
          ..add(_titulo('PROPIETARIO'))
          ..add(
            PopupMenuItem<int>(
              value: _valorPropietario,
              height: 40,
              child: Row(
                children: [
                  Icon(
                    Icons.person_search_outlined,
                    size: 16,
                    color: propietario != null ? Colors.amber : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      propietario ?? 'Filtrar propietario',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: propietario != null ? Colors.amber : black,
                        fontWeight: propietario != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        return items;
      },
    );
  }

  PopupMenuItem<int> _titulo(String texto) => PopupMenuItem<int>(
    enabled: false,
    height: 30,
    child: Text(
      texto,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: Colors.grey,
      ),
    ),
  );
}
