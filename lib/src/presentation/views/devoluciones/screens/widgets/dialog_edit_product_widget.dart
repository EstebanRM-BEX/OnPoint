import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/shared/widgets/segunda_unidad_input_widget.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/product_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/lote_screen.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/widgets/buildBarcodeInputField_widget.dart';

class DialogEditProduct extends StatefulWidget {
  const DialogEditProduct({
    super.key,
    required this.functionValidate,
    required this.focusNode,
    required this.focusNodeQuantityManual,
    required this.controller,
    required this.isEdit,
  });

  final dynamic Function(String) functionValidate;
  final FocusNode focusNode;
  final FocusNode focusNodeQuantityManual;
  final TextEditingController controller;
  final bool isEdit;

  @override
  State<DialogEditProduct> createState() => _DialogEditProductState();
}

class _DialogEditProductState extends State<DialogEditProduct> {
  final FocusNode _focusNodeSegundaUnidad = FocusNode();
  final TextEditingController _controllerManualQuantity =
      TextEditingController();

  @override
  void dispose() {
    _focusNodeSegundaUnidad.dispose();
    _controllerManualQuantity.dispose();
    super.dispose();
  }

  bool _guardSegundaUnidad(DevolucionesBloc bloc) {
    final maneja = bloc.currentProduct.manejaSegundaUnidad;
    if (maneja == true || maneja == 1) {
      if (bloc.segundaUnidadController.text.trim().isEmpty) {
        Get.snackbar(
          'Atención',
          'Debe ingresar la cantidad de la segunda unidad de medida',
          backgroundColor: white,
          colorText: primaryColorApp,
          icon: const Icon(Icons.warning, color: Colors.orange),
        );
        return false;
      }
    }
    return true;
  }

  ProductDevolucion _buildProductDevolucion(DevolucionesBloc bloc,
      {dynamic lotId, String? lotName}) {
    final qSegunda =
        double.tryParse(bloc.segundaUnidadController.text.trim()) ?? 0.0;
    return ProductDevolucion(
      productId: bloc.currentProduct.productId,
      name: bloc.currentProduct.name,
      code: bloc.currentProduct.code,
      barcode: bloc.currentProduct.barcode,
      quantity: bloc.quantitySelected,
      lotId: lotId ?? 0,
      lotName: lotName ?? "",
      uom: bloc.currentProduct.uom,
      tracking: bloc.currentProduct.tracking,
      category: bloc.currentProduct.category,
      expirationTime: bloc.currentProduct.expirationTime,
      useExpirationDate: bloc.currentProduct.useExpirationDate,
      expirationDate: bloc.currentProduct.expirationDate,
      weight: bloc.currentProduct.weight,
      weightUomName: bloc.currentProduct.weightUomName,
      volume: bloc.currentProduct.volume,
      volumeUomName: bloc.currentProduct.volumeUomName,
      locationId: bloc.currentProduct.locationId,
      locationName: bloc.currentProduct.locationName,
      manejaSegundaUnidad: bloc.currentProduct.manejaSegundaUnidad,
      uomSegundaUnidad: bloc.currentProduct.uomSegundaUnidad,
      quantitySegundaUnidad: qSegunda,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async => false,
      child: BlocBuilder<DevolucionesBloc, DevolucionesState>(
        builder: (context, state) {
          final bloc = context.read<DevolucionesBloc>();
          final manejaSegunda = bloc.currentProduct.manejaSegundaUnidad;
          final needsSegunda = manejaSegunda == true || manejaSegunda == 1;

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: AlertDialog(
              actionsAlignment: MainAxisAlignment.spaceBetween,
              contentPadding: const EdgeInsets.all(5),
              title: Center(
                  child: Text('Producto encontrado',
                      style: TextStyle(
                        color: primaryColorApp,
                        fontSize: 16,
                      ))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BuildBarcodeInputField(
                      focusNode: widget.focusNode,
                      functionValidate: (value) {
                        return widget.functionValidate(value);
                      },
                      controller: widget.controller),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bloc.currentProduct.name ?? "",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Barcode: ',
                                      style: TextStyle(
                                          fontSize: 12, color: primaryColorApp),
                                    ),
                                    Text(
                                      '${bloc.currentProduct.barcode}',
                                      style: const TextStyle(
                                          fontSize: 12, color: black),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Código: ',
                                      style: TextStyle(
                                          fontSize: 12, color: primaryColorApp),
                                    ),
                                    Text(
                                      '${bloc.currentProduct.code}',
                                      style: const TextStyle(
                                          fontSize: 12, color: black),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Maneja fecha: ',
                                      style: TextStyle(
                                          fontSize: 12, color: primaryColorApp),
                                    ),
                                    Text(
                                      bloc.currentProduct.useExpirationDate == 1
                                          ? "Si"
                                          : "No",
                                      style: const TextStyle(
                                          fontSize: 12, color: black),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Segunda unidad de medida
                  if (needsSegunda)
                    SegundaUnidadInputWidget(
                      controller: bloc.segundaUnidadController,
                      uomLabel:
                          bloc.currentProduct.uomSegundaUnidad ?? '',
                      focusNode: _focusNodeSegundaUnidad,
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Cantidad: ',
                                style: TextStyle(
                                    fontSize: 12, color: primaryColorApp),
                              ),
                              Text(
                                '${bloc.quantitySelected}',
                                style: const TextStyle(
                                    fontSize: 12, color: black),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  bloc.add(
                                      ShowQuantityEvent(!bloc.viewQuantity));
                                },
                                child: Icon(
                                  Icons.edit,
                                  color: primaryColorApp,
                                  size: 20,
                                  semanticLabel: 'Añadir cantidad',
                                ),
                              ),
                            ],
                          ),
                          if (bloc.viewQuantity) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 35,
                              child: TextFormField(
                                focusNode: widget.focusNodeQuantityManual,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'))
                                ],
                                controller: _controllerManualQuantity,
                                keyboardType: TextInputType.number,
                                maxLines: 1,
                                style: const TextStyle(
                                    fontSize: 12, color: black),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    try {
                                      bloc.quantitySelected =
                                          double.parse(value);
                                    } catch (e) {
                                      debugPrint(
                                          '❌ Error al convertir a número: $e');
                                    }
                                  } else {
                                    bloc.quantitySelected = 0;
                                  }
                                },
                                decoration:
                                    InputDecorations.authInputDecoration(
                                  hintText: 'Cantidad',
                                  labelText: 'Cantidad',
                                  suffixIconButton: IconButton(
                                    onPressed: () {
                                      bloc.add(ShowQuantityEvent(false));
                                      _controllerManualQuantity.clear();
                                    },
                                    icon: const Icon(
                                      Icons.clear,
                                      color: grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (widget.isEdit) ...[
                              const SizedBox(height: 5),
                              Text(
                                  'Reemplazar: reemplaza la cantidad del producto actual por la cantidad ingresada',
                                  style: TextStyle(color: grey, fontSize: 9)),
                              ElevatedButton(
                                onPressed: () {
                                  if (_controllerManualQuantity.text.isEmpty) {
                                    Get.snackbar(
                                      '360 Software Informa',
                                      'No se ha ingresado una cantidad válida',
                                      backgroundColor: white,
                                      colorText: primaryColorApp,
                                      icon: const Icon(Icons.error,
                                          color: Colors.red),
                                    );
                                    return;
                                  }
                                  if (!_guardSegundaUnidad(bloc)) return;

                                  if (bloc.currentProduct.tracking == 'lot') {
                                    if (bloc.lotesProductCurrent.id == null) {
                                      Get.snackbar(
                                        '360 Software Informa',
                                        'El producto no tiene lote asignado',
                                        backgroundColor: white,
                                        colorText: primaryColorApp,
                                        icon: const Icon(Icons.error,
                                            color: Colors.red),
                                      );
                                      return;
                                    } else {
                                      bloc.add(UpdateProductInfoEvent(
                                          isIncrement: false,
                                          quantityManual: 0));
                                      bloc.add(ShowQuantityEvent(false));
                                      _controllerManualQuantity.clear();
                                      Navigator.pop(context);
                                      return;
                                    }
                                  } else {
                                    bloc.add(UpdateProductInfoEvent(
                                        isIncrement: false, quantityManual: 0));
                                    bloc.add(ShowQuantityEvent(false));
                                    _controllerManualQuantity.clear();
                                    Navigator.pop(context);
                                    return;
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColorApp,
                                  minimumSize: Size(size.width * 0.93, 30),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('REMPLAZAR',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14)),
                              ),
                            ],
                            if (widget.isEdit) ...[
                              Text(
                                  'Actualizar: actualiza la cantidad del producto, sumando la cantidad ingresada a la cantidad actual',
                                  style: TextStyle(color: grey, fontSize: 9)),
                            ],
                            ElevatedButton(
                              onPressed: () {
                                if (_controllerManualQuantity.text.isEmpty) {
                                  Get.snackbar(
                                    '360 Software Informa',
                                    'No se ha ingresado una cantidad válida',
                                    backgroundColor: white,
                                    colorText: primaryColorApp,
                                    icon: const Icon(Icons.error,
                                        color: Colors.red),
                                  );
                                  return;
                                }
                                if (!_guardSegundaUnidad(bloc)) return;

                                if (bloc.currentProduct.tracking == 'lot') {
                                  if (bloc.lotesProductCurrent.id == null) {
                                    Get.snackbar(
                                      '360 Software Informa',
                                      'El producto no tiene lote asignado',
                                      backgroundColor: white,
                                      colorText: primaryColorApp,
                                      icon: const Icon(Icons.error,
                                          color: Colors.red),
                                    );
                                    return;
                                  } else {
                                    if (widget.isEdit) {
                                      bloc.add(UpdateProductInfoEvent(
                                          isIncrement: true,
                                          quantityManual: double.parse(
                                              _controllerManualQuantity.text)));
                                    } else {
                                      bloc.add(
                                          ChangeStateIsDialogVisibleEvent(
                                              false));
                                      bloc.add(Addproduct(
                                        _buildProductDevolucion(bloc,
                                            lotId:
                                                bloc.lotesProductCurrent.id,
                                            lotName:
                                                bloc.lotesProductCurrent.name),
                                      ));
                                    }

                                    bloc.add(ShowQuantityEvent(false));
                                    _controllerManualQuantity.clear();
                                    bloc.add(
                                        ChangeStateIsDialogVisibleEvent(false));
                                    Navigator.pop(context);
                                    return;
                                  }
                                } else {
                                  if (widget.isEdit) {
                                    bloc.add(UpdateProductInfoEvent(
                                        isIncrement: true,
                                        quantityManual: double.parse(
                                            _controllerManualQuantity.text)));
                                  } else {
                                    bloc.add(
                                        ChangeStateIsDialogVisibleEvent(false));
                                    bloc.add(Addproduct(
                                      _buildProductDevolucion(bloc),
                                    ));
                                  }
                                  bloc.add(ShowQuantityEvent(false));
                                  _controllerManualQuantity.clear();
                                  bloc.add(
                                      ChangeStateIsDialogVisibleEvent(false));
                                  Navigator.pop(context);
                                  return;
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColorApp,
                                minimumSize: Size(size.width * 0.93, 30),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                  !widget.isEdit
                                      ? 'APLICAR CANTIDAD'
                                      : 'ACTUALIZAR',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!bloc.viewQuantity &&
                      bloc.currentProduct.tracking == 'lot') ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: GestureDetector(
                          onTap: () {
                            bloc.isDialogVisible = true;
                            showDialog(
                              context: context,
                              builder: (context) {
                                return NewLoteScreenDevolucion();
                              },
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                'Lote: ',
                                style: TextStyle(
                                    fontSize: 12, color: primaryColorApp),
                              ),
                              Text(
                                bloc.lotesProductCurrent.name ?? "No asignado",
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        bloc.lotesProductCurrent.name == null
                                            ? red
                                            : black),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios_sharp,
                                color: primaryColorApp,
                                size: 20,
                                semanticLabel: 'Añadir cantidad',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ]
                ],
              ),
              actions: [
                if (!bloc.viewQuantity) ...[
                  ElevatedButton(
                    onPressed: () {
                      bloc.add(ChangeStateIsDialogVisibleEvent(false));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(color: Colors.white)),
                  ),
                  if (!widget.isEdit)
                    ElevatedButton(
                      onPressed: () {
                        if (bloc.quantitySelected <= 0) {
                          Get.snackbar(
                            '360 Software Informa',
                            'La cantidad debe ser mayor a 0',
                            backgroundColor: white,
                            colorText: primaryColorApp,
                            icon:
                                const Icon(Icons.error, color: Colors.red),
                          );
                          return;
                        }
                        if (!_guardSegundaUnidad(bloc)) return;

                        if (bloc.currentProduct.tracking == 'lot') {
                          if (bloc.lotesProductCurrent.id == null) {
                            Get.snackbar(
                              '360 Software Informa',
                              'El producto no tiene lote asignado',
                              backgroundColor: white,
                              colorText: primaryColorApp,
                              icon: const Icon(Icons.error, color: Colors.red),
                            );
                            return;
                          } else {
                            bloc.add(ChangeStateIsDialogVisibleEvent(false));
                            bloc.add(Addproduct(
                              _buildProductDevolucion(bloc,
                                  lotId: bloc.lotesProductCurrent.id,
                                  lotName: bloc.lotesProductCurrent.name),
                            ));
                            Navigator.pop(context);
                            return;
                          }
                        } else {
                          bloc.add(ChangeStateIsDialogVisibleEvent(false));
                          bloc.add(Addproduct(
                            _buildProductDevolucion(bloc),
                          ));
                          Navigator.pop(context);
                          return;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorApp,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Agregar',
                          style: TextStyle(color: Colors.white)),
                    ),
                  if (widget.isEdit)
                    ElevatedButton(
                      onPressed: () {
                        if (!_guardSegundaUnidad(bloc)) return;

                        if (bloc.currentProduct.tracking == 'lot') {
                          if (bloc.lotesProductCurrent.id == null) {
                            Get.snackbar(
                              '360 Software Informa',
                              'El producto no tiene lote asignado',
                              backgroundColor: white,
                              colorText: primaryColorApp,
                              icon: const Icon(Icons.error, color: Colors.red),
                            );
                            return;
                          } else {
                            bloc.add(UpdateProductInfoEvent(
                                isIncrement: false, quantityManual: 0));
                            bloc.add(ChangeStateIsDialogVisibleEvent(false));
                            Navigator.pop(context);
                            return;
                          }
                        } else {
                          bloc.add(UpdateProductInfoEvent(
                              isIncrement: false, quantityManual: 0));
                          bloc.add(ChangeStateIsDialogVisibleEvent(false));
                          Navigator.pop(context);
                          return;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorApp,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Guardar',
                          style: TextStyle(color: Colors.white)),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
