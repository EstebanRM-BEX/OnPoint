// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously, prefer_is_empty

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class Tab3ScreenRecep extends StatelessWidget {
  const Tab3ScreenRecep({
    super.key,
    required this.ordenCompra,
  });

  final ResultEntrada? ordenCompra;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<RecepcionBloc, RecepcionState>(
        listener: (context, state) {
          if (state is DelectedProductWmsLoading) {
            showDialog(
              context: context,
              builder: (context) {
                return const DialogLoading(
                  message: "Eliminando producto",
                );
              },
            );
          }

          if (state is ViewProductImageSuccess) {
            showImageDialog(context, state.imageUrl);
          } else if (state is ViewProductImageFailure) {
            showScrollableErrorDialog(state.error);
          }

          if (state is DelectedProductWmsSuccess) {
            Navigator.pop(context);
            //mostramos una alerta
            Get.snackbar("360 Software Informa", state.message,
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: Icon(Icons.error, color: Colors.green));
          }

          if (state is DelectedProductWmsFailure) {
            Navigator.pop(context);
            showScrollableErrorDialog(state.error);
          }
        },
        builder: (context, state) {
          final recepcionBloc = context.read<RecepcionBloc>();
// 1. Filtrar la lista
          final listDone = recepcionBloc.listProductsEntrada.where((element) {
            return element.isDoneItem == 1;
          }).toList();

// 2. Ordenar tomando en cuenta AÑO, MES, DÍA, HORA, MINUTO Y SEGUNDO
          listDone.sort((a, b) {
            // Convertimos el String a DateTime
            // DateTime.tryParse lee formatos como "2025-12-23 14:45:25" completos
            DateTime dateA =
                DateTime.tryParse(a.dateTransaction ?? '') ?? DateTime(1900);
            DateTime dateB =
                DateTime.tryParse(b.dateTransaction ?? '') ?? DateTime(1900);

            // DESCENDENTE: El tiempo más grande (más reciente) va primero
            // b comparado con a
            return dateB.compareTo(dateA);
          });
          return Scaffold(
            backgroundColor: white,
            body: Container(
              margin: const EdgeInsets.only(top: 5),
              width: double.infinity,
              height: size.height * 0.8,
              child: Column(
                children: [
                  (recepcionBloc.listProductsEntrada.where((element) {
                            return element.isDoneItem == 1;
                          }).length ==
                          0)
                      ? Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Text('No hay productos',
                                  style: TextStyle(fontSize: 14, color: grey)),
                              const Text('Intente buscar otro producto',
                                  style: TextStyle(fontSize: 12, color: grey)),
                              Visibility(
                                visible: context
                                    .read<UserBloc>()
                                    .fabricante
                                    .contains("Zebra"),
                                child: Container(
                                  height: 60,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: recepcionBloc.listProductsEntrada
                                .where((element) {
                              return element.isDoneItem == 1;
                            }).length,
                            itemBuilder: (context, index) {
                              // Obtenemos el producto directamente por su índice
                              final product = listDone[index];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    debugPrint('product: ${product.toMap()}');
                                  },
                                  child: Card(
                                    color: Colors.green[
                                        100], // Color blanco si no está seleccionado
                                    elevation: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  "Producto:",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              //icono de eliminar
                                              GestureDetector(
                                                onTap: () {
                                                  //dialogo de confirmacion
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        backgroundColor:
                                                            Colors.white,
                                                        title: Center(
                                                          child: const Text(
                                                            'Eliminar producto',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ),
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            const Text(
                                                              '¿Está seguro de que desea eliminar este producto?',
                                                              style: TextStyle(
                                                                  color: black),
                                                            ),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            const Text(
                                                              'Después de eliminarlo la cantidad pasara a la lista de productos por hacer.',
                                                              style: TextStyle(
                                                                  color: black),
                                                            ),
                                                          ],
                                                        ),
                                                        actions: <Widget>[
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  grey,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'Cancelar',
                                                              style: TextStyle(
                                                                  color: white),
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              recepcionBloc.add(
                                                                DelectedProductWmsEvent(
                                                                  product.idRecepcion ??
                                                                      0,
                                                                  [
                                                                    product.idMove ??
                                                                        0
                                                                  ],
                                                                ),
                                                              );
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  primaryColorApp,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'Eliminar',
                                                              style: TextStyle(
                                                                  color: white),
                                                            ),
                                                          )
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.delete,
                                                  size: 20,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "${product.productName}",
                                              style: const TextStyle(
                                                  fontSize: 12, color: black),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.code,
                                                color: primaryColorApp,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                "Codigo: ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              Text("${product.productCode}",
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: black)),
                                              const Spacer(),
                                              GestureDetector(
                                                onTap: () {
                                                  context
                                                      .read<RecepcionBloc>()
                                                      .add(
                                                          ViewProductImageEvent(
                                                              int.parse(product
                                                                  .productId)));
                                                },
                                                child: Card(
                                                  //borde
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  elevation: 2,
                                                  color: white,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            2.0),
                                                    child: Icon(
                                                      Icons.image,
                                                      color: primaryColorApp,
                                                      size: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Visibility(
                                            visible:
                                                product.manejaTemperatura ==
                                                        1 ||
                                                    product.manejaTemperatura ==
                                                        true,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.thermostat_outlined,
                                                  color: primaryColorApp,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  "Temperatura: ",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp,
                                                  ),
                                                ),
                                                Text("${product.temperatura}",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black)),
                                                const Spacer(),
                                                Visibility(
                                                  visible:
                                                      product.image != "" &&
                                                          product.image != null,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      showImageDialog(
                                                        context,
                                                        product.image ??
                                                            '', // URL o path de la imagen
                                                      );
                                                    },
                                                    child: Icon(
                                                      Icons.image,
                                                      color: primaryColorApp,
                                                      size: 23,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                            visible: product.productTracking ==
                                                'lot',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.confirmation_num,
                                                  color: primaryColorApp,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  "Lote: ",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp,
                                                  ),
                                                ),
                                                Text("${product.lotName}",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black)),
                                                Text("/${product.loteDate}",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black)),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: primaryColorApp,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                "Ubicación de origen: ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text("${product.locationName}",
                                              style: const TextStyle(
                                                  fontSize: 12, color: black)),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.arrow_forward,
                                                color: primaryColorApp,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                "Ubicación destino: ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              const Spacer(),
//ponemos icono de imprimir
                                              GestureDetector(
                                                onTap: () {
                                                  ModalPrintersList.show(
                                                      context,
                                                      resId: product.idMove);
                                                },
                                                child: Icon(
                                                  Icons.print,
                                                  color: primaryColorApp,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                            ],
                                          ),
                                          Text("${product.locationDestName}",
                                              style: const TextStyle(
                                                  fontSize: 12, color: black)),
                                          Row(
                                            children: [
                                              Visibility(
                                                visible: recepcionBloc
                                                        .configurations
                                                        .result
                                                        ?.result
                                                        ?.hideExpectedQty ==
                                                    false,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.add,
                                                      color: primaryColorApp,
                                                      size: 15,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      "Demanda: ",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: primaryColorApp,
                                                      ),
                                                    ),
                                                    Text(
                                                        "${product.quantityOrdered}",
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: black)),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              Row(
                                                children: [
                                                  Text(
                                                    "Cantidad recibida: ",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp,
                                                    ),
                                                  ),
                                                  Text(
                                                      "${product.quantityDone}",
                                                      // "${product.quantityToReceive}",
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: black)),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                color: primaryColorApp,
                                                size: 15,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                "Tiempo: ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              Text(
                                                  convertirTiempo(
                                                      product.time.toString()),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: black)),
                                            ],
                                          ),
                                          Visibility(
                                            visible:
                                                product.isProductSplit == 1,
                                            child: Row(
                                              children: [
                                                Text(
                                                  "Novedad: ",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: black,
                                                  ),
                                                ),
                                                Text(
                                                  "Producto dividido",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                            visible:
                                                product.observation != "" ||
                                                    product.observation != null,
                                            child: Row(
                                              children: [
                                                Text(
                                                  "Novedad: ",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: black,
                                                  ),
                                                ),
                                                Text(
                                                  product.observation == ""
                                                      ? "Sin novedad"
                                                      : product.observation ??
                                                          "",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Visibility(
                                                  visible:
                                                      product.imageNovedad !=
                                                          "",
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      showImageDialog(
                                                          context,
                                                          product.imageNovedad ??
                                                              '' // URL o path de la imagen
                                                          );
                                                    },
                                                    child: Icon(
                                                      Icons.image,
                                                      color: primaryColorApp,
                                                      size: 23,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String convertirTiempo(String tiempoStr) {
    // Convertimos el string a un double
    double segundos = double.tryParse(tiempoStr) ?? 0.0;
    // Calculamos horas, minutos y segundos
    int horas = (segundos / 3600).floor(); // 3600 segundos = 1 hora
    int minutos =
        ((segundos % 3600) / 60).floor(); // Resto de segundos dividido entre 60
    int segundosRestantes = (segundos % 60).round(); // Resto de segundos
    // Formateamos los valores en 2 dígitos (ej. 01, 02, etc.)
    String horasStr = horas.toString().padLeft(2, '0');
    String minutosStr = minutos.toString().padLeft(2, '0');
    String segundosStr = segundosRestantes.toString().padLeft(2, '0');

    return '$horasStr:$minutosStr:$segundosStr';
  }
}
