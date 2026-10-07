import 'package:flutter/material.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/lista_vacia_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/producto_pack_card.dart';

/// Pestaña "Listo": todas las líneas ya dentro de una caja (solo lectura).
class EmpacadosTab extends StatelessWidget {
  final List<ProductoPacking> empacados;

  const EmpacadosTab({super.key, required this.empacados});

  @override
  Widget build(BuildContext context) {
    if (empacados.isEmpty) {
      return const ListaVaciaPack(
        titulo: 'No hay productos empacados',
        subtitulo: 'Empaque desde "Preparado" o "Por hacer"',
      );
    }
    final ordenados = [...empacados]
      ..sort((a, b) => a.packageName.compareTo(b.packageName));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: ordenados.length,
      itemBuilder: (_, i) => ProductoPackCard(producto: ordenados[i]),
    );
  }
}
