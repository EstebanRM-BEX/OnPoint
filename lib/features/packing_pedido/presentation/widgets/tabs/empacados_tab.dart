import 'package:flutter/material.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/lista_vacia_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/producto_empacado_card.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';

/// Pestaña "Listo": las líneas ya dentro de una caja (solo lectura), con el
/// diseño del módulo anterior.
class EmpacadosTab extends StatelessWidget {
  final List<ProductoPacking> empacados;
  final ValueChanged<int> onVerImagenProducto;

  const EmpacadosTab({
    super.key,
    required this.empacados,
    required this.onVerImagenProducto,
  });

  @override
  Widget build(BuildContext context) {
    if (empacados.isEmpty) {
      return const ListaVaciaPack(
        titulo: 'No hay productos listos',
        subtitulo: 'Intente con otro pedido o batch',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 5),
      itemCount: empacados.length,
      itemBuilder: (_, i) {
        final p = empacados[i];
        return ProductoEmpacadoCard(
          producto: p,
          // Mismo destino que el módulo anterior.
          onImprimir: () =>
              ModalPrintersList.show(context, resIds: [p.idMove], companyId: 1),
          onVerImagenProducto: () => onVerImagenProducto(p.idProduct),
        );
      },
    );
  }
}
