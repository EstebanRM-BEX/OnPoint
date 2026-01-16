// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/update_product_request.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/widgets/info_widget.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/transfer/bloc/transfer_info_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/user/screens/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_numbers_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';

class ProductInfoScreen extends StatelessWidget {
  const ProductInfoScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<InfoRapidaBloc>();
    final product = bloc.infoRapidaResult.result;

    // Verificación de seguridad: Si no hay producto, mostrar error y volver
    if (product == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cargar la información del producto'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // referenceController
    TextEditingController referenceController = TextEditingController(
      text: product.referencia ?? '',
    );

    //unidade de medida
    TextEditingController uomController = TextEditingController(
      text: product.unidadMedida ?? '',
    );

    // priceController
    TextEditingController priceController = TextEditingController(
      text: product.precio != null ? '${product.precio}' : '',
    );
    // pesoController
    TextEditingController pesoController = TextEditingController(
      text: product.peso != null ? '${product.peso}' : '',
    );
    // volumenController
    TextEditingController volumenController = TextEditingController(
      text: product.volumen != null ? '${product.volumen}' : '',
    );

    // barcodeController
    TextEditingController barcodeController = TextEditingController(
      text: product.codigoBarras ?? '',
    );

    // nameController
    TextEditingController nameController = TextEditingController(
      text: product.nombre ?? '',
    );

    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listener: (context, state) {
        print("state product info 👹 $state");
        if (state is UpdateProductSuccess) {
          Get.snackbar(
            '360 Software Informa',
            'Producto actualizado exitosamente',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );
        } else if (state is UpdateProductFailure) {
          Get.snackbar(
            '360 Software Informa',
            state.error,
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        } else if (state is ViewProductImageSuccess) {
          showImageDialog(context, state.imageUrl);
        } else if (state is ViewProductImageFailure) {
          showScrollableErrorDialog(state.error);
        }
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            backgroundColor: white,
            bottomNavigationBar: bloc.isKeyboardVisible &&
                    context.read<UserBloc>().fabricante.contains("Zebra")
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: bloc.isNumericKeyboardType
                        ? CustomKeyboardNumber(
                            controller: bloc.controllerActivo!,
                            onchanged: () {},
                          )
                        : CustomKeyboard(
                            isLogin: false,
                            controller: bloc.controllerActivo!,
                            onchanged: () {},
                          ))
                : null,
            body: Column(
              mainAxisSize: MainAxisSize.min, // Ocupa solo el espacio necesario
              children: [
                AppBar(size: size),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: size.width * 1,
                    child: Card(
                      elevation: 3,
                      color: white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('Imagen del producto',
                                    style: TextStyle(
                                        color: black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    context.read<InfoRapidaBloc>().add(
                                        ViewProductImageEvent(
                                            product?.id ?? 0));
                                  },
                                  child: Card(
                                    elevation: 2,
                                    color: white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.image,
                                        color: primaryColorApp,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            EditableReferenceRow(
                              title: 'Nombre: ',
                              isEditMode: bloc.isEdit,
                              onTap: () {
                                context.read<InfoRapidaBloc>().add(
                                    ShowKeyboardInfoEvent(true, nameController,
                                        isNumeric: false));
                              },
                              controller: nameController,
                              isName: true,
                              isExpanded: true,
                            ),
                            EditableReferenceRow(
                              title: 'Referencia: ',
                              isEditMode: bloc.isEdit,
                              isNumber: true,
                              onTap: () {
                                context.read<InfoRapidaBloc>().add(
                                    ShowKeyboardInfoEvent(
                                        true, referenceController,
                                        isNumeric: true));
                              },
                              controller: referenceController,
                              isExpanded:
                                  context.read<InfoRapidaBloc>().isExpanded,
                            ),
                            EditableReferenceRow(
                              title: 'Unidad: ',
                              isEditMode: false,
                              isNumber: false,
                              onTap: () {},
                              controller: uomController,
                              isExpanded:
                                  context.read<InfoRapidaBloc>().isExpanded,
                            ),
                            EditableReferenceRow(
                              title: 'Precio: ',
                              isEditMode: bloc.isEdit,
                              onTap: () {
                                context.read<InfoRapidaBloc>().add(
                                    ShowKeyboardInfoEvent(true, priceController,
                                        isNumeric: true));
                              },
                              controller: priceController,
                              isNumber: true,
                              isExpanded:
                                  context.read<InfoRapidaBloc>().isExpanded,
                            ),
                            EditableReferenceRow(
                              title: 'Peso Kg: ',
                              isEditMode: bloc.isEdit,
                              onTap: () {
                                context.read<InfoRapidaBloc>().add(
                                    ShowKeyboardInfoEvent(true, pesoController,
                                        isNumeric: true));
                              },
                              controller: pesoController,
                              isNumber: true,
                              isExpanded:
                                  context.read<InfoRapidaBloc>().isExpanded,
                            ),
                            EditableReferenceRow(
                              title: 'Volumen m3: ',
                              isEditMode: bloc.isEdit,
                              onTap: () {
                                context.read<InfoRapidaBloc>().add(
                                    ShowKeyboardInfoEvent(
                                        true, volumenController,
                                        isNumeric: true));
                              },
                              controller: volumenController,
                              isNumber: true,
                              isExpanded:
                                  context.read<InfoRapidaBloc>().isExpanded,
                            ),
                            EditableReferenceRow(
                              title: 'Barcode: ',
                              isEditMode: bloc.isEdit,
                              isNumber: true,
                              onTap: () {
                                context.read<InfoRapidaBloc>().add(
                                    ShowKeyboardInfoEvent(
                                        true, barcodeController,
                                        isNumeric: true));
                              },
                              controller: barcodeController,
                              isExpanded:
                                  context.read<InfoRapidaBloc>().isExpanded,
                            ),
                            EditableReferenceRow(
                              title: 'Categoria: ',
                              isEditMode: false,
                              onTap: () {},
                              controller: TextEditingController(
                                text: '${product?.categoria}',
                              ),
                              isExpanded:
                                  context.read<InfoRapidaBloc>().isExpanded,
                            ),
                            EditableReferenceRow(
                              title: 'Disponible: ',
                              isEditMode: false,
                              onTap: () {},
                              controller: TextEditingController(
                                text: '${product?.cantidadDisponible} UND',
                              ),
                              isExpanded:
                                  context.read<InfoRapidaBloc>().isExpanded,
                            ),
                            EditableReferenceRow(
                              title: 'Previsto: ',
                              isEditMode: false,
                              onTap: () {},
                              controller: TextEditingController(
                                text: '${product?.previsto} UND',
                              ),
                              isExpanded:
                                  context.read<InfoRapidaBloc>().isExpanded,
                            ),
                            Visibility(
                              visible: bloc.isEdit,
                              child: Center(
                                child: ElevatedButton(
                                    onPressed: () {
                                      //validamos que todos los campos esten llenos
                                      if (nameController.text.isEmpty ||
                                          barcodeController.text.isEmpty ||
                                          referenceController.text.isEmpty ||
                                          priceController.text.isEmpty ||
                                          pesoController.text.isEmpty ||
                                          volumenController.text.isEmpty) {
                                        Get.snackbar(
                                          '360 Software Informa',
                                          'Por favor, complete todos los campos',
                                          backgroundColor: white,
                                          colorText: primaryColorApp,
                                          icon: const Icon(Icons.check_circle,
                                              color: Colors.red),
                                        );
                                        return;
                                      }

                                      bloc.add(UpdateProductEvent(
                                          UpdateProductRequest(
                                        productId: product?.id ?? 0,
                                        name: nameController.text,
                                        barcode: barcodeController.text,
                                        defaultCode: referenceController.text,
                                        listPrice: priceController.text,
                                        weight: pesoController.text,
                                        volume: volumenController.text,
                                      )));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(size.width * 0.9, 30),
                                      backgroundColor: primaryColorApp,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text('Actualizar',
                                        style: TextStyle(
                                            color: white, fontSize: 12))),
                              ),
                            )

                            ///icono de desplegable
                            ,
                            GestureDetector(
                              onTap: () {
                                context.read<InfoRapidaBloc>().add(
                                    ToggleProductExpansionEvent(!context
                                        .read<InfoRapidaBloc>()
                                        .isExpanded));
                              },
                              child: Icon(
                                context.read<InfoRapidaBloc>().isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: primaryColorApp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 20),
                  child: Row(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Ubicaciones",
                          style: TextStyle(
                              color: black,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          context.read<InfoRapidaBloc>().add(SortLocationsEvent(
                              !context.read<InfoRapidaBloc>().isAscending));
                        },
                        child: Row(
                          children: [
                            Text(
                              "Ordenar ",
                              style: TextStyle(
                                  color: black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              context.read<InfoRapidaBloc>().isAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: primaryColorApp,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10)
                    ],
                  ),
                ),

                //listado de ubicaciones
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ListView.builder(
                    itemExtent:
                        175, // Altura fija por item para mejor rendimiento
                    cacheExtent: 500, // Precarga 500px adicionales
                    padding: const EdgeInsets.all(0),
                    itemCount: product?.ubicaciones?.length ?? 0,
                    itemBuilder: (contextList, index) {
                      // Verificación de seguridad para evitar acceso a índice inválido
                      if (product?.ubicaciones == null ||
                          index >= (product?.ubicaciones?.length ?? 0)) {
                        return const SizedBox.shrink();
                      }

                      final ubicacion = product?.ubicaciones?[index];
                      return Card(
                        elevation: 2,
                        color: white,
                        child: ListTile(
                          title: Text(
                            ubicacion?.ubicacion ?? 'Sin nombre',
                            style: TextStyle(
                                color: primaryColorApp,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            children: [
                              ProductInfoRow(
                                title:
                                    'Cantidad disponible: ', // Este parece repetido, si es correcto, déjalo así
                                value:
                                    '${ubicacion?.cantidadMano} ${ubicacion?.unidadMedida ?? 'UND'}',
                                color: green,
                              ),
                              ProductInfoRow(
                                title:
                                    'En inventario: ', // Este parece repetido, si es correcto, déjalo así
                                value:
                                    '${ubicacion?.cantidad}  ${ubicacion?.unidadMedida ?? 'UND'}',
                              ),
                              ProductInfoRow(
                                title:
                                    'Cantidad reservada: ', // Este parece repetido, si es correcto, déjalo así
                                value:
                                    '${ubicacion?.reservado} ${ubicacion?.unidadMedida ?? 'UND'}',
                                color: red,
                              ),
                              ProductInfoRow(
                                title:
                                    'Lote: ', // Este parece repetido, si es correcto, déjalo así
                                value: ubicacion?.lote == null ||
                                        ubicacion?.lote == ''
                                    ? 'Sin lote'
                                    : ubicacion?.lote ?? 'Sin lote',
                              ),
                              ProductInfoRow(
                                title:
                                    'Fecha de entrada: ', // Este parece repetido, si es correcto, déjalo así
                                value: '${ubicacion?.fechaEntrada}',
                              ),
                              ProductInfoRow(
                                title:
                                    'Fecha de eliminacion: ', // Este parece repetido, si es correcto, déjalo así
                                value: ubicacion?.fechaEliminacion == null ||
                                        ubicacion?.fechaEliminacion == ''
                                    ? 'Sin fecha de eliminacion'
                                    : '${ubicacion?.fechaEliminacion}',
                              ),
                              const SizedBox(height: 5),
                              GestureDetector(
                                onTap: () async {
                                  context
                                      .read<TransferInfoBloc>()
                                      .add(LoadLocationsTransfer());

                                  context
                                      .read<TransferInfoBloc>()
                                      .add(SetDateStartEventTransfer());

                                  showDialog(
                                    context: contextList,
                                    builder: (contextList) {
                                      return const DialogLoading(
                                        message: "Cargando informacion...",
                                      );
                                    },
                                  );

                                  //esperamos 1 segundo
                                  await Future.delayed(
                                    const Duration(seconds: 1),
                                  );

                                  // Verificar si el contexto sigue siendo válido antes de navegar
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    Navigator.pushReplacementNamed(
                                        context, 'transfer-info',
                                        arguments: [product, ubicacion]);
                                  }
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: size.width * 0.4,
                                    child: Card(
                                      color: white,
                                      elevation: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.compare_arrows_sharp,
                                              color: primaryColorApp,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 5),
                                            Text('TRANSFERIR',
                                                style: TextStyle(
                                                    color: primaryColorApp,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )),
                const SizedBox(
                  height: 20,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppBar extends StatelessWidget {
  const AppBar({
    super.key,
    required this.size,
  });

  final Size size;

  @override
  Widget build(BuildContext context) {
    // 1. Agregamos esta lógica de seguridad antes de construir el widget
    bool showEditIcon = false;
    try {
      final configurations = context.read<InfoRapidaBloc>().configurations;
      // Verificamos si configurations tiene datos antes de intentar acceder a sus hijos
      if (configurations.result != null) { 
         showEditIcon = configurations.result?.result?.updateItemInventory == true;
      }
    } catch (e) {
      // Si ocurre el error "No element", simplemente ocultamos el icono
      showEditIcon = false;
    }

    return Container(
      decoration: BoxDecoration(
        color: primaryColorApp,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      width: double.infinity,
      child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
          builder: (context, status) {
        return Column(
          children: [
            const WarningWidgetCubit(),
            Padding(
              padding: EdgeInsets.only(
                  left: size.width * 0.05,
                  right: size.width * 0.05,
                  bottom: 10,
                  top: status != ConnectionStatus.online ? 0 : 35),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      context.read<InfoRapidaBloc>().add(IsEditEvent(false));
                      context.read<InfoRapidaBloc>().add(ShowKeyboardInfoEvent(
                          false, TextEditingController()));
                      context.read<InfoRapidaBloc>().add(GetProductsList());
                      Navigator.pushReplacementNamed(
                        context,
                        'info-rapida',
                      );
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: white,
                      size: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: size.width * 0.1),
                    child: const Text("INFORMACIÓN RÁPIDA",
                        style: TextStyle(color: white, fontSize: 18)),
                  ),
                  const Spacer(),
                  // 2. Usamos la variable segura aquí
                  Visibility(
                    visible: showEditIcon, // Usamos el booleano calculado arriba
                    child: GestureDetector(
                      onTap: () {
                        context.read<InfoRapidaBloc>().add(IsEditEvent(
                            !context.read<InfoRapidaBloc>().isEdit));
                        context.read<InfoRapidaBloc>().add(
                            ShowKeyboardInfoEvent(
                                false, TextEditingController()));
                      },
                      child: Icon(
                        context.read<InfoRapidaBloc>().isEdit
                            ? Icons.close
                            : Icons.edit,
                        color: white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
