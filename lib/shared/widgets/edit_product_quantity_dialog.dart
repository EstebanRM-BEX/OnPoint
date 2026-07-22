import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';

/// Diálogo genérico para editar la cantidad separada/pickeada de un producto,
/// con selección opcional de novedad. Usado por picking_cluster, Pick y
/// Batchs: cada pantalla conserva su propio bloc/entidad y solo entrega los
/// datos ya calculados más los callbacks de negocio (guardado y regla de
/// exceso), vía un wrapper delgado.
///
/// Regla de novedad: el dropdown aparece y es obligatorio seleccionar una
/// novedad siempre que la cantidad ingresada sea MENOR a la cantidad
/// restante (quantityRequested - quantitySeparated), incluyendo 0. Antes,
/// Pick y Batchs solo la pedían cuando la cantidad era exactamente 0; este
/// widget unifica el comportamiento con el que ya tenía picking_cluster.
class EditProductQuantityDialog extends StatefulWidget {
  final String productId;
  final double quantityRequested;
  final double quantitySeparated;
  final List<Novedad> novedades;

  /// Novedad ya guardada previamente para este producto (si existe), para
  /// precargar el dropdown en vez de empezar siempre vacío.
  final String? initialNovedad;

  /// Se invoca ya validado (cantidad correcta y, si aplica, novedad
  /// seleccionada). Debe realizar el guardado real (actualizar cantidad
  /// separada + novedad si aplica). Si lanza, el diálogo permanece abierto
  /// y muestra un error genérico.
  final Future<void> Function(double cantidad, String? novedad) onConfirm;

  /// Regla de negocio adicional para exceso, evaluada solo cuando la
  /// cantidad ya supera la restante. Por defecto siempre es error (igual
  /// que picking_cluster y Pick). Batchs la usa para permitir exceso en
  /// productos tipo 'components' según permisos.
  final bool Function(double cantidad, double quantityRemaining)?
      isExcessError;

  final String confirmButtonLabel;

  const EditProductQuantityDialog({
    super.key,
    required this.productId,
    required this.quantityRequested,
    required this.quantitySeparated,
    required this.novedades,
    required this.onConfirm,
    this.initialNovedad,
    this.isExcessError,
    this.confirmButtonLabel = 'AGREGAR CANTIDAD',
  });

  @override
  State<EditProductQuantityDialog> createState() =>
      _EditProductQuantityDialogState();
}

class _EditProductQuantityDialogState
    extends State<EditProductQuantityDialog> {
  static const double _tolerance = 0.000001;

  final TextEditingController _controller = TextEditingController();
  String _alerta = '';
  String? _selectedNovedad;
  bool _isSubmitting = false;

  late final double _quantityRemaining = double.parse(
      (widget.quantityRequested - widget.quantitySeparated)
          .toStringAsFixed(4));

  @override
  void initState() {
    super.initState();
    _selectedNovedad = widget.initialNovedad;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isExcess(double cantidad) {
    if (cantidad == 0) return false;
    if (cantidad - _quantityRemaining <= _tolerance) return false;
    return widget.isExcessError?.call(cantidad, _quantityRemaining) ?? true;
  }

  bool get _isPartial {
    final cantidad = double.tryParse(_controller.text.replaceAll(',', '.'));
    return (cantidad ?? _quantityRemaining) < _quantityRemaining;
  }

  void _onChanged(String value) {
    if (value.isEmpty) {
      setState(() => _alerta = '');
      return;
    }
    final cantidad = double.tryParse(value.replaceAll(',', '.'));
    if (cantidad == null) {
      setState(() => _alerta = 'Por favor ingresa un número válido.');
    } else if (cantidad < _quantityRemaining) {
      setState(() => _alerta =
          'Cantidad menor: seleccione novedad o continúe escribiendo.');
    } else if (_isExcess(cantidad)) {
      setState(() =>
          _alerta = 'La cantidad no puede ser mayor a la cantidad restante');
    } else {
      setState(() => _alerta = '');
    }
  }

  Future<void> _onSubmit() async {
    final cantidad =
        double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0.0;

    if (cantidad < _quantityRemaining && _selectedNovedad == null) {
      setState(() => _alerta = 'Debe seleccionar una novedad');
      return;
    }
    if (_isExcess(cantidad)) {
      setState(() =>
          _alerta = 'La cantidad no puede ser mayor a la cantidad restante');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm(cantidad, _selectedNovedad);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _alerta = 'No se pudo guardar, intenta de nuevo';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return AlertDialog(
      title: Center(
        child: Text(
          'Editar Cantidad del Producto\n${widget.productId}',
          textAlign: TextAlign.center,
          style: TextStyle(color: primaryColorApp, fontSize: 13),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.add, color: primaryColorApp, size: 20),
                const SizedBox(width: 5),
                const Text('Unidades:',
                    style: TextStyle(fontSize: 13, color: black)),
                const SizedBox(width: 5),
                Text(widget.quantityRequested.toString(),
                    style: const TextStyle(fontSize: 13, color: green)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.check, color: primaryColorApp, size: 20),
                const SizedBox(width: 5),
                const Text('Separadas:',
                    style: TextStyle(fontSize: 13, color: black)),
                const SizedBox(width: 5),
                Text(widget.quantitySeparated.toString(),
                    style: const TextStyle(fontSize: 13, color: Colors.amber)),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                const TextSpan(
                    text: 'La cantidad a completar es de ',
                    style: TextStyle(fontSize: 13, color: black)),
                TextSpan(
                  text: '$_quantityRemaining ',
                  style: TextStyle(
                    fontSize: 13,
                    color: primaryColorApp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 35,
              child: TextFormField(
                controller: _controller,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: const TextStyle(fontSize: 14, color: Colors.black),
                decoration: InputDecorations.authInputDecoration(
                  hintText: 'Cantidad',
                  labelText: 'Cantidad',
                  suffixIconButton: IconButton(
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                    icon: Icon(Icons.clear, color: primaryColorApp, size: 20),
                  ),
                ),
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(height: 5),
            Visibility(
              visible: _isPartial,
              child: Card(
                color: Colors.white,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    underline: Container(height: 0),
                    borderRadius: BorderRadius.circular(10),
                    focusColor: Colors.white,
                    isExpanded: true,
                    isDense: true,
                    hint: const Text('Seleccionar novedad',
                        style: TextStyle(fontSize: 14, color: black)),
                    icon: SizedBox(
                      height: 20,
                      width: 20,
                      child: SvgPicture.asset(
                        color: primaryColorApp,
                        'assets/icons/novedad.svg',
                        height: 20,
                        width: 20,
                        fit: BoxFit.cover,
                      ),
                    ),
                    value: _selectedNovedad,
                    alignment: Alignment.centerLeft,
                    style: const TextStyle(color: black, fontSize: 14),
                    items: widget.novedades.map((Novedad item) {
                      return DropdownMenuItem<String>(
                        value: item.name,
                        child: Text(item.name),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (String? newValue) {
                            setState(() => _selectedNovedad = newValue);
                          },
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_alerta,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ElevatedButton(
                onPressed: (_controller.text.isEmpty || _isSubmitting)
                    ? null
                    : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  minimumSize: Size(size.width * 0.93, 35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(widget.confirmButtonLabel,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
