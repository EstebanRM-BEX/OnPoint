import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/src/presentation/views/devoluciones/models/product_devolucion_model.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/lote_screen.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/widgets/buildBarcodeInputField_widget.dart';

class DialogEditProduct extends StatelessWidget {
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
  Widget build(BuildContext context) {
    TextEditingController controllerManualQuantity = TextEditingController();

    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        // Evita que el diálogo se cierre al presionar el botón de retroceso
        return false;
      },
      child: BlocBuilder<DevolucionesBloc, DevolucionesState>(
        builder: (context, state) {
          final bloc = context.read<DevolucionesBloc>();
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
                mainAxisSize: MainAxisSize.min, // Ajusta el tamaño del diálogo
                children: [
                  BuildBarcodeInputField(
                      focusNode: focusNode,
                      functionValidate: (value) {
                        return functionValidate(value);
                      },
                      controller: controller),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icono o imagen del producto
                          // Puedes usar Image.network(product.imageUrl) si tienes URLs de imagen
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
                                style:
                                    const TextStyle(fontSize: 12, color: black),
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
                                focusNode: focusNodeQuantityManual,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'))
                                ],
                                controller: controllerManualQuantity,
                                keyboardType: TextInputType.number,
                                maxLines: 1,
                                style:
                                    const TextStyle(fontSize: 12, color: black),
                                onChanged: (value) {
                                  // Actualiza la cantidad seleccionada
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
                                // onFieldSubmitted: onManualQuantitySubmitted,
                                decoration:
                                    InputDecorations.authInputDecoration(
                                  hintText: 'Cantidad',
                                  labelText: 'Cantidad',
                                  suffixIconButton: IconButton(
                                    onPressed: () {
                                      bloc.add(ShowQuantityEvent(false));
                                      controllerManualQuantity.clear();
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
                            if (isEdit) ...[
                              const SizedBox(height: 5),
                              Text(
                                  'Reemplazar: reemplaza la cantidad del producto actual por la cantidad ingresada',
                                  style: TextStyle(color: grey, fontSize: 9)),
                              ElevatedButton(
                                onPressed: () {
                                  //Validamos que la cantidad manual sea mayor a 0
                                  if (controllerManualQuantity.text.isEmpty) {
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
                                      controllerManualQuantity.clear();
                                      Navigator.pop(context);
                                      return;
                                    }
                                  } else {
                                    bloc.add(UpdateProductInfoEvent(
                                        isIncrement: false, quantityManual: 0));
                                    bloc.add(ShowQuantityEvent(false));
                                    controllerManualQuantity.clear();
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
                            if (isEdit) ...[
                              Text(
                                  'Actualizar: actualiza la cantidad del producto, sumando la cantidad ingresada a la cantidad actual',
                                  style: TextStyle(color: grey, fontSize: 9)),
                            ],
                            ElevatedButton(
                              onPressed: () {
                                if (controllerManualQuantity.text.isEmpty) {
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
                                    if (isEdit) {
                                      bloc.add(UpdateProductInfoEvent(
                                          isIncrement: true,
                                          quantityManual: double.parse(
                                              controllerManualQuantity.text)));
                                    } else {
                                      bloc.add(ChangeStateIsDialogVisibleEvent(
                                          false));
                                      bloc.add(Addproduct(
                                        ProductDevolucion(
                                          productId:
                                              bloc.currentProduct.productId,
                                          name: bloc.currentProduct.name,
                                          code: bloc.currentProduct.code,
                                          barcode: bloc.currentProduct.barcode,
                                          quantity: bloc.quantitySelected,
                                          lotId: bloc.lotesProductCurrent.id,
                                          lotName:
                                              bloc.lotesProductCurrent.name,
                                          uom: bloc.currentProduct.uom,
                                          tracking:
                                              bloc.currentProduct.tracking,
                                          category:
                                              bloc.currentProduct.category,
                                          expirationTime: bloc
                                              .currentProduct.expirationTime,
                                          useExpirationDate: bloc
                                              .currentProduct.useExpirationDate,
                                          expirationDate: bloc
                                              .currentProduct.expirationDate,
                                          weight: bloc.currentProduct.weight,
                                          weightUomName:
                                              bloc.currentProduct.weightUomName,
                                          volume: bloc.currentProduct.volume,
                                          volumeUomName:
                                              bloc.currentProduct.volumeUomName,
                                          locationId:
                                              bloc.currentProduct.locationId,
                                          locationName:
                                              bloc.currentProduct.locationName,
                                        ),
                                      ));
                                    }

                                    bloc.add(ShowQuantityEvent(false));
                                    controllerManualQuantity.clear();

                                    bloc.add(
                                        ChangeStateIsDialogVisibleEvent(false));
                                    // bloc.add(ClearScannedValueEvent('product'));
                                    Navigator.pop(context);
                                    return;
                                  }
                                } else {
                                  if (isEdit) {
                                    bloc.add(UpdateProductInfoEvent(
                                        isIncrement: true,
                                        quantityManual: double.parse(
                                            controllerManualQuantity.text)));
                                  } else {
                                    bloc.add(
                                        ChangeStateIsDialogVisibleEvent(false));
                                    bloc.add(Addproduct(
                                      ProductDevolucion(
                                        productId:
                                            bloc.currentProduct.productId,
                                        name: bloc.currentProduct.name,
                                        code: bloc.currentProduct.code,
                                        barcode: bloc.currentProduct.barcode,
                                        quantity: bloc.quantitySelected,
                                        lotId: bloc.lotesProductCurrent.id,
                                        lotName: bloc.lotesProductCurrent.name,
                                        uom: bloc.currentProduct.uom,
                                        tracking: bloc.currentProduct.tracking,
                                        category: bloc.currentProduct.category,
                                        expirationTime:
                                            bloc.currentProduct.expirationTime,
                                        useExpirationDate: bloc
                                            .currentProduct.useExpirationDate,
                                        expirationDate:
                                            bloc.currentProduct.expirationDate,
                                        weight: bloc.currentProduct.weight,
                                        weightUomName:
                                            bloc.currentProduct.weightUomName,
                                        volume: bloc.currentProduct.volume,
                                        volumeUomName:
                                            bloc.currentProduct.volumeUomName,
                                        locationId:
                                            bloc.currentProduct.locationId,
                                        locationName:
                                            bloc.currentProduct.locationName,
                                      ),
                                    ));
                                  }
                                  bloc.add(ShowQuantityEvent(false));
                                  controllerManualQuantity.clear();

                                  bloc.add(
                                      ChangeStateIsDialogVisibleEvent(false));
                                  // bloc.add(ClearScannedValueEvent('product'));
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
                                  !isEdit ? 'APLICAR CANTIDAD' : 'ACTUALIZAR',
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
                                    color: bloc.lotesProductCurrent.name == null
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
                      // bloc.add(ClearScannedValueEvent('product'));
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
                  if (!isEdit)
                    ElevatedButton(
                      onPressed: () {
                        if (bloc.quantitySelected <= 0) {
                          Get.snackbar(
                            '360 Software Informa',
                            'La cantidad debe ser mayor a 0',
                            backgroundColor: white,
                            colorText: primaryColorApp,
                            icon: const Icon(Icons.error, color: Colors.red),
                          );
                          return;
                        }

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
                              ProductDevolucion(
                                productId: bloc.currentProduct.productId,
                                name: bloc.currentProduct.name,
                                code: bloc.currentProduct.code,
                                barcode: bloc.currentProduct.barcode,
                                quantity: bloc.quantitySelected,
                                lotId: bloc.lotesProductCurrent.id,
                                lotName: bloc.lotesProductCurrent.name,
                                uom: bloc.currentProduct.uom,
                                tracking: bloc.currentProduct.tracking,
                                category: bloc.currentProduct.category,
                                expirationTime:
                                    bloc.currentProduct.expirationTime,
                                useExpirationDate:
                                    bloc.currentProduct.useExpirationDate,
                                expirationDate:
                                    bloc.currentProduct.expirationDate,
                                weight: bloc.currentProduct.weight,
                                weightUomName:
                                    bloc.currentProduct.weightUomName,
                                volume: bloc.currentProduct.volume,
                                volumeUomName:
                                    bloc.currentProduct.volumeUomName,
                                locationId: bloc.currentProduct.locationId,
                                locationName: bloc.currentProduct.locationName,
                              ),
                            ));
                            Navigator.pop(context);
                            return;
                          }
                        } else {
                          bloc.add(ChangeStateIsDialogVisibleEvent(false));
                          bloc.add(Addproduct(
                            ProductDevolucion(
                              productId: bloc.currentProduct.productId,
                              name: bloc.currentProduct.name,
                              code: bloc.currentProduct.code,
                              barcode: bloc.currentProduct.barcode,
                              quantity: bloc.quantitySelected,
                              lotId: 0,
                              lotName: "",
                              uom: bloc.currentProduct.uom,
                              tracking: bloc.currentProduct.tracking,
                              category: bloc.currentProduct.category,
                              expirationTime:
                                  bloc.currentProduct.expirationTime,
                              useExpirationDate:
                                  bloc.currentProduct.useExpirationDate,
                              expirationDate:
                                  bloc.currentProduct.expirationDate,
                              weight: bloc.currentProduct.weight,
                              weightUomName: bloc.currentProduct.weightUomName,
                              volume: bloc.currentProduct.volume,
                              volumeUomName: bloc.currentProduct.volumeUomName,
                              locationId: bloc.currentProduct.locationId,
                              locationName: bloc.currentProduct.locationName,
                            ),
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
                  if (isEdit)
                    ElevatedButton(
                      onPressed: () {
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
                            // bloc.add(ClearScannedValueEvent('product'));
                            Navigator.pop(context);
                            return;
                          }
                        } else {
                          bloc.add(UpdateProductInfoEvent(
                              isIncrement: false, quantityManual: 0));

                          bloc.add(ChangeStateIsDialogVisibleEvent(false));
                          // bloc.add(ClearScannedValueEvent('product'));
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
