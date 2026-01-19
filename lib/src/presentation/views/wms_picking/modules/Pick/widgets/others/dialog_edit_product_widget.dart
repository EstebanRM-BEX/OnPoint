// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/core/utils/theme/input_decoration.dart';
import 'package:wms_app/src/presentation/models/novedades_response_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/user/screens/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/picking_batch_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_numbers_widget.dart';

class DialogEditProductPickWidget extends StatefulWidget {
  final ProductsBatch productsBatch;

  const DialogEditProductPickWidget({
    super.key,
    required this.productsBatch,
  });

  @override
  State<DialogEditProductPickWidget> createState() =>
      _DialogEditProductWidgetState();
}

class _DialogEditProductWidgetState extends State<DialogEditProductPickWidget> {
  // ✅ Mover el controlador al State
  final TextEditingController _quantityController = TextEditingController();

  // Variables locales para estado de UI
  final double _tolerance = 0.000001;
  String _alerta = "";
  String? _selectedNovedad;

  // Variables calculadas
  late double _quantityRemaining;
  late double _maxQuantityAllowed;

  @override
  void initState() {
    super.initState();
    // Inicializar valores calculados
    _quantityRemaining = widget.productsBatch.quantity -
        (widget.productsBatch.quantitySeparate ?? 0);
    _maxQuantityAllowed = _quantityRemaining;
  }

  @override
  void didChangeDependencies() {
    // ✅ Solución del error ProviderNotFoundException: Carga de BLoC aquí
    context.read<PickingPickBloc>().add(LoadAllNovedadesPickEvent());
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _quantityController.dispose(); // Liberar el controlador local
    super.dispose();
  }

  // ✅ Lógica de validación centralizada (Usa el controller local)
  void _validateAndSetAlert(String value) {
    if (value.isEmpty) {
      setState(() {
        _alerta = "";
      });
      return;
    }

    final double? cantidad = double.tryParse(value);

    if (cantidad == null) {
      setState(() {
        _alerta = "Por favor ingresa un número válido.";
      });
    } else if (cantidad == 0.0 && _selectedNovedad == null) {
      setState(() {
        _alerta = "Debe seleccionar una novedad si la cantidad es 0.";
      });
    } else if (cantidad > _maxQuantityAllowed + _tolerance) {
      setState(() {
        _alerta = "La cantidad no puede ser mayor a la cantidad restante";
      });
    } else {
      setState(() {
        _alerta = "";
      });
    }
  }

  // ✅ Lógica final de AGREGAR CANTIDAD (Centralizada y robusta)
  void _onAddQuantityPressed() async {
    final bloc = context.read<PickingPickBloc>();
    final double cantidad = double.tryParse(_quantityController.text) ?? 0.0;

    // Ejecutar validación final antes de enviar
    if (cantidad == 0 && _selectedNovedad == null) {
      setState(() {
        _alerta = "Debe seleccionar una novedad";
      });
      return;
    }
    if (cantidad > _maxQuantityAllowed + _tolerance) {
      setState(() {
        _alerta = "La cantidad no puede ser mayor a la cantidad restante";
      });
      return;
    }
    if (_alerta.isNotEmpty) return; // Si hay una alerta activa, no proceder

    final dynamic cantidadReuqest =
        (widget.productsBatch.quantitySeparate ?? 0) + cantidad;

    // Lógica de Novedad
    if (_selectedNovedad != null && cantidad == 0) {
      DataBaseSqlite db = DataBaseSqlite();
      await db.updateNovedad(
          widget.productsBatch.batchId ?? 0,
          widget.productsBatch.idProduct ?? 0,
          _selectedNovedad ?? '',
          widget.productsBatch.idMove ?? 0,
          'pick');
    }

    // Actualizar la cantidad en el BLoC y BD
    bloc.add(ChangeQuantitySeparate(cantidadReuqest,
        widget.productsBatch.idProduct ?? 0, widget.productsBatch.idMove ?? 0));

    bloc.add(SendProductEditOdooEvent(
      widget.productsBatch,
      cantidadReuqest,
    ));

    Navigator.pop(context); // Cierra el diálogo
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // El texto de la cantidad restante
    final String remainingText = (_quantityRemaining ?? 0.0).toString();

    return AlertDialog(
      title: Center(
        child: Text(
            "Editar Cantidad del Producto\n${widget.productsBatch.productId}",
            textAlign: TextAlign.center,
            style: TextStyle(color: primaryColorApp, fontSize: 13)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ... (Info de Unidades y Separadas) ...

            // Sección de Ingreso de Cantidad
            SizedBox(
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      const TextSpan(
                          text: "La cantidad a completar es de ",
                          style: TextStyle(fontSize: 13, color: black)),
                      TextSpan(
                          text:
                              "$remainingText ", // Usamos la variable calculada
                          style: TextStyle(
                              fontSize: 13,
                              color: primaryColorApp,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 35,
                    child: TextFormField(
                      showCursor: false,
                      readOnly: true, // Siempre true si usas CustomKeyboard
                      controller:
                          _quantityController, // ✅ Usar el controller local
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      decoration: InputDecorations.authInputDecoration(
                        hintText: 'Cantidad',
                        labelText: 'Cantidad',
                        suffixIconButton: IconButton(
                          onPressed: () {
                            _quantityController.clear();
                            _validateAndSetAlert(""); // Recalcular alerta
                          },
                          icon: Icon(
                            Icons.clear,
                            color: primaryColorApp,
                            size: 20,
                          ),
                        ),
                      ),
                      // El onChanged ya no necesita el controlador del BLoC
                      onChanged:
                          context.read<UserBloc>().fabricante.contains("Zebra")
                              ? null
                              : _validateAndSetAlert,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Dropdown de Novedades
                  Visibility(
                    // La visibilidad se basa en si la cantidad es 0 o si ya se seleccionó una novedad
                    visible: _quantityController.text.isEmpty ||
                        double.tryParse(_quantityController.text) == 0,
                    child: Card(
                      color: Colors.white,
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: BlocBuilder<PickingPickBloc, PickingPickState>(
                            builder: (context, state) {
                          return DropdownButton<String>(
                            underline: Container(height: 0),
                            value: _selectedNovedad,
                            items: context
                                .read<PickingPickBloc>()
                                .novedades
                                .map((Novedad item) {
                              return DropdownMenuItem<String>(
                                value: item.name,
                                child: Text(item.name ?? ''),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedNovedad = newValue;
                                _validateAndSetAlert(_quantityController
                                    .text); // Revalidar la cantidad
                              });
                            },
                            hint: const Text('Seleccionar novedad',
                                style: TextStyle(fontSize: 14, color: black)),
                            isExpanded: true,
                            icon: SizedBox(
                              height: 20,
                              width: 20,
                              child: SvgPicture.asset(
                                color: primaryColorApp,
                                "assets/icons/novedad.svg",
                                height: 20,
                                width: 20,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_alerta, // ✅ Usar la alerta local
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12))),

                  // Botón AGREGAR CANTIDAD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ElevatedButton(
                      // ✅ Lógica de habilitación simplificada
                      onPressed: (_quantityController.text.isNotEmpty &&
                                  _alerta.isEmpty) ||
                              (double.tryParse(_quantityController.text) == 0 &&
                                  _selectedNovedad != null)
                          ? _onAddQuantityPressed
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorApp,
                        minimumSize: Size(size.width * 0.93, 35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: BlocBuilder<PickingPickBloc, PickingPickState>(
                        builder: (context, state) {
                          if (state is LoadingSendProductEdit) {
                            return const CircularProgressIndicator(
                                color: Colors.white);
                          }
                          return const Text('AGREGAR CANTIDAD',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14));
                        },
                      ),
                    ),
                  ),

                  // Teclado Virtual
                  CustomKeyboardNumber(
                    controller:
                        _quantityController, // ✅ Usar el controller local
                    onchanged: () =>
                        _validateAndSetAlert(_quantityController.text),
                    isDialog: true,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
