// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously, prefer_is_empty

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/bloc/transferencia_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class Tab3ScreenTrans extends StatelessWidget {
  const Tab3ScreenTrans({
    super.key,
    // required this.ordenCompra,
  });

  // final ResultEntrada? ordenCompra;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<TransferenciaBloc, TransferenciaState>(
        listener: (context, state) {
          print('state: $state');

          if (state is ViewProductImageSuccess) {
            showImageDialog(context, state.imageUrl);
          } else if (state is ViewProductImageFailure) {
            showScrollableErrorDialog(state.error);
          }

          if (state is DeleteLineTransferLoading) {
            showDialog(
              context: context,
              builder: (context) {
                return const DialogLoading(
                  message: "Eliminando producto",
                );
              },
            );
          } else if (state is DeleteLineTransferFailure) {
            Navigator.pop(context);
            showScrollableErrorDialog(state.error);
          } else if (state is DeleteLineTransferSuccess) {
            Navigator.pop(context);
            //mostramos una alerta
            Get.snackbar(
                "360 Software Informa", "Producto eliminado correctamente",
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: Icon(Icons.error, color: Colors.green));
          }
        },
        builder: (context, state) {
          final bloc = context.read<TransferenciaBloc>();

          return Scaffold(
            backgroundColor: white,
            body: Container(
              margin: const EdgeInsets.only(top: 5),
              width: double.infinity,
              height: size.height * 0.8,
              child: Column(
                children: [
                  (bloc.listProductsTransfer.where((element) {
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
                            itemCount:
                                bloc.listProductsTransfer.where((element) {
                              return element.isDoneItem == 1;
                            }).length,
                            itemBuilder: (context, index) {
                              final product =
                                  bloc.listProductsTransfer.where((element) {
                                return element.isDoneItem == 1;
                              }).elementAt(index);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
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
                                            GestureDetector(
                                              onTap: () {
                                                //dialogo de confirmcion de eliminar
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
                                                            bloc.add(DeleteLineTransferEvent(
                                                                product
                                                                    .idMove!,
                                                                int.parse(product
                                                                    .productId!),
                                                                product
                                                                    .idTransferencia!));
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
                                              child: const Icon(
                                                Icons.delete,
                                                size: 20,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                "${product.productName}",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: black),
                                              ),
                                            ),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () {
                                                context
                                                    .read<TransferenciaBloc>()
                                                    .add(ViewProductImageEvent(
                                                        int.parse(product
                                                                .productId ??
                                                            "0")));
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
                                          visible: product.productTracking ==
                                              'lot',
                                          child: Row(
                                            children: [
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
                                              // Text("/${product.loteDate}",
                                              //     style: const TextStyle(
                                              //         fontSize: 12,
                                              //         color: black)),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "Ubicación de origen: ",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: primaryColorApp,
                                              ),
                                            ),
                                            Text("${product.locationName}",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: black)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "Ubicación destino: ",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: primaryColorApp,
                                              ),
                                            ),
                                            Text(
                                                "${product.locationDestName}",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: black)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Row(
                                              children: [
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
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
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
                                                "Cantidad dividida",
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
                                                    : product.observation,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
