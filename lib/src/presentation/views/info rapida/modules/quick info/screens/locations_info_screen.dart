// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/models/info_rapida_model.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/widgets/info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

class LocationInfoScreen extends StatelessWidget {
  final InfoRapidaResult? infoRapidaResult;

  const LocationInfoScreen({Key? key, this.infoRapidaResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<InfoRapidaBloc>();

    final ubicacion = bloc.infoRapidaResult.result;
    // barcodeController
    TextEditingController barcodeController = TextEditingController(
      text: ubicacion?.codigoBarras ?? '',
    );

    // nameController
    TextEditingController nameController = TextEditingController(
      text: ubicacion?.nombre ?? '',
    );

    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listener: (context, state) {
        if (state is InfoRapidaLoading) {
          showDialog(
            context: context,
            builder: (context) {
              return const DialogLoading(
                message: "Buscando informacion...",
              );
            },
          );
        } else if (state is InfoRapidaLoaded) {
          Navigator.pop(context);
          if (state.infoRapidaResult.type == 'product') {
            Navigator.pushReplacementNamed(
              context,
              'product-info',
            );
          }
        } else if (state is InfoRapidaError) {
          Navigator.pop(context);
          Get.snackbar(
            '360 Software Informa',
            'No se encontró información.',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            backgroundColor: white,
            body: SizedBox(
              width: size.width * 1,
              height: size.height * 1,
              child: Column(
                children: [
                  AppBar(size: size, infoRapidaResult: infoRapidaResult),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Ubicación",
                        style: TextStyle(
                            color: black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
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
                                EditableReferenceRow(
                                  title: 'Nombre: ',
                                  isEditMode: bloc.isEdit,
                                  onTap: () {
                                    // context.read<InfoRapidaBloc>().add(
                                    //     ShowKeyboardInfoEvent(
                                    //         true, nameController,
                                    //         isNumeric: false));
                                  },
                                  controller: nameController,
                                  isNumber: false,
                                  isName: false,
                                  isExpanded: true,
                                ),
                                EditableReferenceRow(
                                  title: 'Barcode: ',
                                  isEditMode: bloc.isEdit,
                                  isNumber: false,
                                  onTap: () {
                                    // context.read<InfoRapidaBloc>().add(
                                    //     ShowKeyboardInfoEvent(
                                    //         true, barcodeController,
                                    //         isNumeric: false));
                                  },
                                  controller: barcodeController,
                                  isExpanded: true,
                                ),
                                ProductInfoRow(
                                  title: 'Ubicación padre:',
                                  value:
                                      ubicacion?.ubicacionPadre ?? "Sin nombre",
                                ),
                                ProductInfoRow(
                                  title: 'Ubicación tipo: ',
                                  value: '${ubicacion?.tipoUbicacion}',
                                ),
                                Visibility(
                                  visible: bloc.isEdit,
                                  child: Center(
                                    child: ElevatedButton(
                                        onPressed: () {
                                          //validamos que todos los campos esten llenos
                                          if (nameController.text.isEmpty ||
                                              barcodeController.text.isEmpty) {
                                            Get.snackbar(
                                              '360 Software Informa',
                                              'Por favor, complete todos los campos',
                                              backgroundColor: white,
                                              colorText: primaryColorApp,
                                              icon: const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.red),
                                            );
                                            return;
                                          }

                                          bloc.add(EditLocationEvent(
                                            ubicacion?.id ?? 0,
                                            nameController.text,
                                            barcodeController.text,
                                          ));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              Size(size.width * 0.9, 30),
                                          backgroundColor: primaryColorApp,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text('Actualizar',
                                            style: TextStyle(
                                                color: white, fontSize: 12))),
                                  ),
                                )
                              ],
                            )),
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
                            "Productos",
                            style: TextStyle(
                                color: black,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            context.read<InfoRapidaBloc>().add(
                                SortProductsEvent(!context
                                    .read<InfoRapidaBloc>()
                                    .isAscending));
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

                  //listado de productos
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ListView.builder(
                            padding: const EdgeInsets.all(0),
                            itemCount: ubicacion?.productos?.length ?? 0,
                            itemBuilder: (context, index) {
                              final producto = ubicacion?.productos?[index];
                              return Card(
                                  color: white,
                                  elevation: 3,
                                  child: ListTile(
                                    trailing:

                                        //CheckBox para seleccionar productos para transferencia masiva

                                        context
                                                .read<InfoRapidaBloc>()
                                                .isMassTransferActive
                                            ?

                                            //VALIDAMOS QUE EL PRODUCTO NO ESTE EN UN PAQUETE y su cantidad disponible sea mayor a 0
                                            producto?.packing == true ||
                                                    producto?.cantidadMano ==
                                                        0.0
                                                ? null
                                                : Checkbox(
                                                    value: context
                                                        .read<InfoRapidaBloc>()
                                                        .productosFiltersMassTransfer
                                                        .any((p) =>
                                                            p.id ==
                                                            producto?.id),
                                                    onChanged: (bool? value) {
                                                      context
                                                          .read<
                                                              InfoRapidaBloc>()
                                                          .add(
                                                              ToggleProductMassTransferEvent(
                                                                  producto!,
                                                                  value ??
                                                                      false));
                                                    },
                                                  )
                                            : IconButton(
                                                icon: Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 20,
                                                    color: primaryColorApp),
                                                onPressed: () async {
                                                  getInfoProduct(
                                                      producto?.id.toString() ??
                                                          '',
                                                      context);
                                                },
                                              ),
                                    title: Text(
                                      producto?.producto ?? 'Sin nombre',
                                      style: TextStyle(
                                          color: primaryColorApp,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      children: [
                                        ProductInfoRow(
                                          title: 'Cantidad disponible: ',
                                          value:
                                              '${producto?.cantidadMano} ${producto?.unidadMedida}',
                                          color: green,
                                        ),
                                        ProductInfoRow(
                                          title: 'En inventario: ',
                                          value:
                                              '${producto?.cantidad} ${producto?.unidadMedida}',
                                        ),
                                        ProductInfoRow(
                                          title: 'Cantidad reservada: ',
                                          value:
                                              '${producto?.reservado} ${producto?.unidadMedida}',
                                          color: red,
                                        ),
                                        ProductInfoRow(
                                          title: 'Barcode: ',
                                          value: producto?.codigoBarras == false
                                              ? 'Sin barcode'
                                              : '${producto?.codigoBarras}',
                                        ),
                                        ProductInfoRow(
                                          title: 'Lote: ',
                                          value: producto?.lote == null ||
                                                  producto?.lote == ""
                                              ? "Sin lote"
                                              : "${producto?.lote}",
                                          color: producto?.lote == null ||
                                                  producto?.lote == ""
                                              ? Colors.red
                                              : black,
                                        ),
                                        //fecha de vencimiento
                                        ProductInfoRow(
                                          title: 'Caducidad :',
                                          value: producto?.fechaVencimiento ==
                                                      null ||
                                                  producto?.fechaVencimiento ==
                                                      ""
                                              ? "Sin caducidad"
                                              : "${producto?.fechaVencimiento}",
                                          color: producto?.fechaVencimiento ==
                                                      null ||
                                                  producto?.fechaVencimiento ==
                                                      ""
                                              ? Colors.red
                                              : black,
                                        ),
                                        //producto en paquete
                                        ProductInfoRow(
                                          title: 'Paquete :',
                                          value: producto?.packing == true
                                              ? "${producto?.nombrePaquete}"
                                              : "Sin paquete",
                                          color: producto?.packing == true
                                              ? black
                                              : Colors.red,
                                        ),
                                      ],
                                    ),
                                  ));
                            })),
                  ),

                  //btn de crear trasnferencia masiva
                  if (context.read<InfoRapidaBloc>().isMassTransferActive)
                    ElevatedButton(
                        onPressed: () {
                          if (context
                              .read<InfoRapidaBloc>()
                              .productosFiltersMassTransfer
                              .isEmpty) {
                            Get.snackbar(
                              '360 Software Informa',
                              'Debe seleccionar al menos un producto para realizar la transferencia masiva',
                              backgroundColor: white,
                              colorText: primaryColorApp,
                              icon: const Icon(Icons.error, color: Colors.red),
                            );
                            return;
                          }
                          Navigator.pushReplacementNamed(
                            context,
                            'create-mass-transfer',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(size.width * 0.9, 30),
                          backgroundColor: primaryColorApp,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Crear transferencia masiva",
                          style: TextStyle(color: white),
                        ))
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void getInfoProduct(String id, BuildContext context) {
    context
        .read<InfoRapidaBloc>()
        .add(GetInfoRapida(id.toUpperCase(), true, true, false));
  }
}

class AppBar extends StatelessWidget {
  const AppBar({
    super.key,
    required this.size,
    required this.infoRapidaResult,
  });

  final InfoRapidaResult? infoRapidaResult;
  final Size size;

  @override
  Widget build(BuildContext context) {
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
                children: [
                  GestureDetector(
                    onTap: () {
                      context.read<InfoRapidaBloc>().add(IsEditEvent(false));
                      context
                          .read<InfoRapidaBloc>()
                          .add(ResetProductsFiltersMassTransferEvent());
                      context
                          .read<InfoRapidaBloc>()
                          .add(GetListLocationsEvent());
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
                  PopupMenuButton<String>(
                    // Usamos more_vert (3 puntos) o edit según prefieras
                    icon: Icon(
                      context.read<InfoRapidaBloc>().isEdit
                          ? Icons
                              .close // Si está editando, mostramos X para intuir cerrar
                          : Icons.more_vert, // Si no, mostramos menú
                      color: white,
                      size: 20,
                    ),
                    onSelected: (String value) {
                      if (value == 'edit') {
                        if (context
                                .read<InfoRapidaBloc>()
                                .configurations
                                .result
                                ?.result
                                ?.updateLocationInventory ==
                            true) {
                          // Lógica original de Editar Ubicación
                          context.read<InfoRapidaBloc>().add(IsEditEvent(
                              !context.read<InfoRapidaBloc>().isEdit));
                        } else {
                          Get.snackbar(
                            '360 Software Informa',
                            'No tiene permiso para editar la ubicación',
                            backgroundColor: white,
                            colorText: primaryColorApp,
                            icon: const Icon(Icons.error, color: Colors.red),
                          );
                        }
                      } else if (value == 'mass_transfer') {
                        context.read<InfoRapidaBloc>().add(
                            ActivateMassTransferEvent(!context
                                .read<InfoRapidaBloc>()
                                .isMassTransferActive));
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      // Verificamos si ya está en modo edición para cambiar el texto del menú
                      final isEditing = context.read<InfoRapidaBloc>().isEdit;

                      return [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                isEditing ? Icons.close : Icons.edit,
                                color: Colors
                                    .black54, // Color para el menú (fondo blanco por defecto)
                              ),
                              const SizedBox(width: 10),
                              Text(isEditing
                                  ? "Cancelar edición"
                                  : "Editar ubicación"),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'mass_transfer',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .swap_horiz, // Icono sugerido para transferencia
                                color: Colors.black54,
                              ),
                              SizedBox(width: 10),
                              Text(context
                                      .read<InfoRapidaBloc>()
                                      .isMassTransferActive
                                  ? "Desactivar transferencia masiva"
                                  : "Activar transferencia masiva"),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
