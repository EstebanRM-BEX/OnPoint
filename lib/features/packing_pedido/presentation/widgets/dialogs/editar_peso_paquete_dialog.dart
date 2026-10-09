import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_formatos.dart';

/// Pide el nuevo peso de la caja. Devuelve el peso o null si se cancela.
Future<double?> showEditarPesoPaqueteDialog(
  BuildContext context,
  PaquetePacking paquete,
) => showDialog<double>(
  context: context,
  builder: (_) => _EditarPesoPaqueteDialog(paquete: paquete),
);

class _EditarPesoPaqueteDialog extends StatefulWidget {
  final PaquetePacking paquete;

  const _EditarPesoPaqueteDialog({required this.paquete});

  @override
  State<_EditarPesoPaqueteDialog> createState() =>
      _EditarPesoPaqueteDialogState();
}

class _EditarPesoPaqueteDialogState extends State<_EditarPesoPaqueteDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    final peso = widget.paquete.peso;
    _controller = TextEditingController(
      text: peso > 0 ? PackFormatos.cantidad(peso) : '',
    );
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _guardar() {
    final peso = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (peso == null || peso <= 0) {
      setState(() => _error = 'Ingrese un peso mayor a cero');
      return;
    }
    Navigator.pop(context, peso);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: white,
      title: Text(
        'Editar peso',
        textAlign: TextAlign.center,
        style: TextStyle(color: primaryColorApp, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.paquete.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: primaryColorApp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Peso actual: ${PackFormatos.cantidad(widget.paquete.peso)} kg',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: black),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,3}')),
            ],
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _guardar(),
            decoration: InputDecoration(
              labelText: 'Peso',
              suffixText: 'kg',
              errorText: _error,
              prefixIcon: Icon(Icons.scale, color: primaryColorApp),
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColorApp),
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: grey),
          child: const Text('Cancelar', style: TextStyle(color: white)),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(backgroundColor: primaryColorApp),
          child: const Text('Guardar', style: TextStyle(color: white)),
        ),
      ],
    );
  }
}
