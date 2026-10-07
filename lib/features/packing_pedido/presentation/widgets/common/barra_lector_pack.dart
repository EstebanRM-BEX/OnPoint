import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Franja superior de las pestañas con escáner: indicador del lector
/// (contiene el campo invisible), buscar y seleccionar todos.
class BarraLectorPack extends StatelessWidget {
  final Widget lector;
  final String texto;
  final bool buscando;
  final VoidCallback? onBuscar;

  /// null = sin botón de seleccionar todos.
  final VoidCallback? seleccionTodos;
  final bool todosSeleccionados;
  final List<Widget> acciones;

  const BarraLectorPack({
    super.key,
    required this.lector,
    required this.texto,
    this.buscando = false,
    this.onBuscar,
    this.seleccionTodos,
    this.todosSeleccionados = false,
    this.acciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 2),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_scanner, color: primaryColorApp, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // El campo de escaneo es invisible; queda detrás del texto.
                lector,
                IgnorePointer(
                  child: Text(
                    buscando ? 'Buscando…' : texto,
                    style: const TextStyle(fontSize: 12, color: grey),
                  ),
                ),
              ],
            ),
          ),
          ...acciones,
          if (onBuscar != null)
            IconButton(
              tooltip: buscando ? 'Cerrar búsqueda' : 'Buscar',
              icon: Icon(
                buscando ? Icons.search_off : Icons.search,
                color: primaryColorApp,
              ),
              onPressed: onBuscar,
            ),
          if (seleccionTodos != null)
            IconButton(
              tooltip: todosSeleccionados
                  ? 'Quitar selección'
                  : 'Seleccionar todos',
              icon: Icon(
                todosSeleccionados ? Icons.checklist_rtl : Icons.checklist,
                color: primaryColorApp,
              ),
              onPressed: seleccionTodos,
            ),
        ],
      ),
    );
  }
}
