import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/detail/packing_pedido_detail_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/lista_vacia_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/producto_pack_card.dart';

/// Pestaña "Preparado": líneas separadas sin caja. Se seleccionan para
/// empacar (certificado) o se deshace la separación.
class PreparadosTab extends StatelessWidget {
  final PackingPedidoDetailState state;
  final VoidCallback onEmpacar;
  final ValueChanged<ProductoPacking> onDeshacer;

  const PreparadosTab({
    super.key,
    required this.state,
    required this.onEmpacar,
    required this.onDeshacer,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PackingPedidoDetailBloc>();
    final listos = state.detalle?.listos ?? const <ProductoPacking>[];
    final seleccion = state.seleccionadosListos;
    final todos = listos.isNotEmpty && seleccion.length == listos.length;
    final editable = !state.pedidoTerminado;

    return Scaffold(
      backgroundColor: white,
      floatingActionButton: editable && seleccion.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'fab-pack-preparados',
              backgroundColor: primaryColorApp,
              onPressed: onEmpacar,
              icon: const Icon(Icons.inventory_2, color: white),
              label: Text(
                'Empacar (${seleccion.length})',
                style: const TextStyle(color: white),
              ),
            )
          : null,
      body: listos.isEmpty
          ? const ListaVaciaPack(
              titulo: 'No hay productos preparados',
              subtitulo: 'Separe productos desde "Por hacer"',
            )
          : Column(
              children: [
                if (editable)
                  CheckboxListTile(
                    dense: true,
                    value: todos,
                    activeColor: primaryColorApp,
                    title: Text(
                      'Seleccionar todos (${listos.length})',
                      style: TextStyle(fontSize: 13, color: primaryColorApp),
                    ),
                    onChanged: (v) => bloc.add(
                      SeleccionPackReemplazada(
                        v == true ? listos.map((p) => p.id) : const [],
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: listos.length,
                    itemBuilder: (_, i) {
                      final p = listos[i];
                      return ProductoPackCard(
                        producto: p,
                        seleccionado: editable
                            ? state.seleccionados.contains(p.id)
                            : null,
                        onSeleccionar: (v) => bloc.add(
                          ProductoPackSeleccionado(p.id, seleccionado: v),
                        ),
                        accion: editable
                            ? IconButton(
                                tooltip: 'Devolver a por hacer',
                                icon: const Icon(Icons.undo, color: red),
                                onPressed: () => onDeshacer(p),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
