import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';

/// Paso de cantidad: contador escaneado / total, edición manual (con
/// permiso) y "Aplicar cantidad".
class CantidadScanCard extends StatelessWidget {
  final bool activo;
  final double cantidad;
  final double total;
  final String unidades;
  final bool editando;
  final bool puedeEditar;
  final bool ocupado;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAlternarEdicion;
  final VoidCallback onAplicar;

  const CantidadScanCard({
    super.key,
    required this.activo,
    required this.cantidad,
    required this.total,
    required this.unidades,
    required this.editando,
    required this.puedeEditar,
    required this.ocupado,
    required this.controller,
    required this.focusNode,
    required this.onAlternarEdicion,
    required this.onAplicar,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = PackFormatos.cantidad;
    final avance = total <= 0 ? 0.0 : (cantidad / total).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: activo ? white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: activo ? primaryColorApp : const Color(0xFFE2E8F0),
          width: activo ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.numbers, color: primaryColorApp, size: 18),
              const SizedBox(width: 6),
              Text(
                'Cantidad',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColorApp,
                ),
              ),
              const Spacer(),
              if (activo && puedeEditar)
                IconButton(
                  tooltip: editando ? 'Volver al escáner' : 'Digitar cantidad',
                  icon: Icon(
                    editando ? Icons.qr_code_scanner : Icons.edit_note_rounded,
                    color: primaryColorApp,
                  ),
                  onPressed: onAlternarEdicion,
                ),
            ],
          ),
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: fmt(cantidad),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: primaryColorApp,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${fmt(total)} ${unidades.trim()}',
                    style: const TextStyle(fontSize: 16, color: grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: avance,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              color: avance >= 1 ? green : primaryColorApp,
            ),
          ),
          if (editando) ...[
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => onAplicar(),
            ),
          ],
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: activo && !ocupado ? onAplicar : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'APLICAR CANTIDAD',
              style: TextStyle(color: white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
