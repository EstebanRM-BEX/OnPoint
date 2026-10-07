import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/detail/packing_pedido_detail_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/lista_vacia_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/producto_preparado_card.dart';

/// Pestaña "Preparado": como en el módulo anterior, el botón empaca todos
/// los preparados (sin selección) y cada tarjeta permite eliminar el
/// producto, que vuelve a "Por hacer".
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
    final listos = state.detalle?.listos ?? const <ProductoPacking>[];
    final editable = !state.pedidoTerminado;

    return Scaffold(
      backgroundColor: white,
      floatingActionButton: editable && listos.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'fab-pack-preparados',
              backgroundColor: primaryColorApp,
              onPressed: onEmpacar,
              icon: const Icon(Icons.inventory_2, color: white),
              label: Text(
                'Empacar (${listos.length})',
                style: const TextStyle(color: white),
              ),
            )
          : null,
      body: listos.isEmpty
          ? const ListaVaciaPack(
              titulo: 'No hay productos preparados',
              subtitulo: 'Intente con otro pedido o batch',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 5, bottom: 90),
              itemCount: listos.length,
              itemBuilder: (_, i) => ProductoPreparadoCard(
                producto: listos[i],
                onEliminar: editable ? () => onDeshacer(listos[i]) : null,
              ),
            ),
    );
  }
}
