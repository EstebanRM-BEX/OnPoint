import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/bloc/crate_transfer_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class DetailCreateTransferScreen extends StatelessWidget {
  const DetailCreateTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<CreateTransferBloc, CreateTransferState>(
      listener: (context, state) {
        if (state is ProductRemovingFromTransferLoadingState) {
          //mostrar loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(
                child: CircularProgressIndicator(
                  color: primaryColorApp,
                ),
              );
            },
          );
        } else if (state is ProductRemovedFromTransferState) {
          //ocultar loading
          Navigator.of(context).pop();
          //mostrar mensaje de éxito
          Get.snackbar(
            '360 Software Informa',
            'Producto eliminado de la transferencia',
            backgroundColor: Colors.white,
            colorText: primaryColorApp,
            icon: Icon(Icons.check, color: Colors.green),
          );
        } else if (state is ProductRemoveFromTransferErrorState) {
          //ocultar loading
          Navigator.of(context).pop();
          //mostrar error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is CreateTransferSuccess) {
          //mostramos un dialogo con la informacion de la transferencia creada
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: AlertDialog(
                  backgroundColor: Colors.white,
                  title: Center(
                    child: Text(
                      '360 Software Informa',
                      style: TextStyle(color: primaryColorApp, fontSize: 20),
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.response.result?.msg ?? "Transferencia creada",
                        style: TextStyle(color: green),
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Nombre de transferencia: ",
                          style: TextStyle(color: black),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          state.response.result?.nombreTransferencia ?? "",
                          style: TextStyle(
                              color: primaryColorApp,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      //total de items
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            "Total de items: ",
                            style: TextStyle(color: black),
                          ),
                          Text(
                            "${state.response.result?.totalItems ?? 0}",
                            style: TextStyle(
                                color: primaryColorApp,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(
                              context, 'create-transfer');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColorApp,
                          minimumSize: Size(size.width * 0.6, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'ACEPTAR',
                          style: TextStyle(color: white),
                        ),
                      ),
                    ],
                  ),
                  actions: <Widget>[],
                ),
              );
            },
          );
        } else if (state is CreateTransferFailure) {
          showScrollableErrorDialog(state.error);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: white,
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: Column(
              children: [
                //*AppBar
                Container(
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
                              bottom: 0,
                              top: status != ConnectionStatus.online ? 0 : 25),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.arrow_back, color: white),
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                      context, 'create-transfer');
                                },
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.only(left: size.width * 0.25),
                                child: const Text("DETALLES",
                                    style:
                                        TextStyle(color: white, fontSize: 18)),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Total de productos: ",
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryColorApp,
                              ),
                            ),
                            Text(
                                "${context.read<CreateTransferBloc>().productosCreateTransfer.length}",
                                style: const TextStyle(
                                    fontSize: 14, color: black)),
                          ],
                        ),

                        //ubicacion de origen
                        Text(
                          "Ubicación de origen: ",
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColorApp,
                          ),
                        ),
                        Text(
                            context
                                    .read<CreateTransferBloc>()
                                    .currentUbication
                                    ?.name ??
                                "Sin ubicación",
                            style: TextStyle(
                                fontSize: 14,
                                color: context
                                                .read<CreateTransferBloc>()
                                                .currentUbication
                                                ?.name ==
                                            null ||
                                        context
                                                .read<CreateTransferBloc>()
                                                .currentUbication
                                                ?.name ==
                                            ""
                                    ? red
                                    : black)),
                        Text(
                          "Ubicación destino: ",
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColorApp,
                          ),
                        ),
                        Text(
                            context
                                    .read<CreateTransferBloc>()
                                    .currentUbicationDest
                                    ?.name ??
                                "Sin ubicación",
                            style: TextStyle(
                                fontSize: 14,
                                color: context
                                                .read<CreateTransferBloc>()
                                                .currentUbicationDest
                                                ?.name ==
                                            null ||
                                        context
                                                .read<CreateTransferBloc>()
                                                .currentUbicationDest
                                                ?.name ==
                                            ""
                                    ? red
                                    : black)),
                      ],
                    ),
                  ),
                ),

                Center(
                  child: Text(
                    "Productos agregados",
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryColorApp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                (context
                        .read<CreateTransferBloc>()
                        .productosCreateTransfer
                        .isEmpty)
                    ? Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Text('No hay productos agregados',
                                style: TextStyle(fontSize: 14, color: grey)),
                            const Text(
                                'Intente agregar productos a la transferencia',
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
                        padding: const EdgeInsets.only(top: 0),
                        itemBuilder: (context, index) {
                          final product = context
                              .read<CreateTransferBloc>()
                              .productosCreateTransfer[index];
                          return Padding(
                              padding: const EdgeInsets.only(
                                  left: 10, right: 10, top: 5),
                              child: GestureDetector(
                                onTap: () {
                                  print(
                                      "Producto seleccionado: ${product.toMap()}");
                                },
                                child: Card(
                                    elevation: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
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
                                                              context
                                                                  .read<
                                                                      CreateTransferBloc>()
                                                                  .add(
                                                                    RemoveProductFromTransferEvent(
                                                                        product),
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
                                                child: const Icon(
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
                                              "${product.name}",
                                              style: const TextStyle(
                                                  fontSize: 12, color: black),
                                            ),
                                          ),
                                          Visibility(
                                            visible: product.tracking == 'lot',
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
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                            visible: product.tracking ==
                                                    'lot' &&
                                                product.useExpirationDate == 1,
                                            child: Row(
                                              children: [
                                                Text(
                                                  "Fecha de caducidad: ",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp,
                                                  ),
                                                ),
                                                Text(
                                                    "${product.expirationDateLote}",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black)),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "Barcode: ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  product.barcode == null ||
                                                          product.barcode == ""
                                                      ? "Sin barcode"
                                                      : "${product.barcode}",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: product.barcode ==
                                                                  null ||
                                                              product.barcode ==
                                                                  ""
                                                          ? red
                                                          : black),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "Código: ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  product.code == null ||
                                                          product.code == ""
                                                      ? "Sin código"
                                                      : "${product.code}",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: product.code ==
                                                                  null ||
                                                              product.code == ""
                                                          ? red
                                                          : black),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "Cantidad: ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  product.quantityDone == null
                                                      ? "0.0"
                                                      : "${product.quantityDone}",
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                ),
                                              ),
                                              const Spacer(),
                                              //unidad
                                              Text(
                                                "Unidad: ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              Text(
                                                product.uom == null
                                                    ? "Sin unidad"
                                                    : "${product.uom}",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: product.uom ==
                                                                null ||
                                                            product.uom == ""
                                                        ? red
                                                        : black),
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
                                        ],
                                      ),
                                    )),
                              ));
                        },
                        itemCount: context
                            .read<CreateTransferBloc>()
                            .productosCreateTransfer
                            .length,
                      )),

                if (context
                    .read<CreateTransferBloc>()
                    .productosCreateTransfer
                    .isNotEmpty) ...[
                  ElevatedButton(
                      onPressed: () {
                        //validamos que tenga ubicacion de origen y destino
                        if (context
                                    .read<CreateTransferBloc>()
                                    .currentUbication ==
                                null ||
                            context
                                    .read<CreateTransferBloc>()
                                    .currentUbication
                                    ?.name ==
                                "") {
                          Get.snackbar(
                            '360 Software Informa',
                            'Debe seleccionar una ubicación de origen',
                            backgroundColor: Colors.white,
                            colorText: primaryColorApp,
                            icon: Icon(Icons.warning, color: Colors.orange),
                          );
                          return;
                        }

                        if (context
                                    .read<CreateTransferBloc>()
                                    .currentUbicationDest ==
                                null ||
                            context
                                    .read<CreateTransferBloc>()
                                    .currentUbicationDest
                                    ?.name ==
                                "") {
                          Get.snackbar(
                            '360 Software Informa',
                            'Debe seleccionar una ubicación destino',
                            backgroundColor: Colors.white,
                            colorText: primaryColorApp,
                            icon: Icon(Icons.warning, color: Colors.orange),
                          );
                          return;
                        }

                        //dialogo de confirmacion

                        Get.defaultDialog(
                          title: '360 Software Informa',
                          titleStyle:
                              TextStyle(color: primaryColorApp, fontSize: 18),
                          middleText:
                              '¿Está seguro de que desea crear la transferencia?',
                          middleTextStyle:
                              TextStyle(color: black, fontSize: 14),
                          backgroundColor: Colors.white,
                          radius: 10,
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text('Cancelar',
                                  style: TextStyle(color: white)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context
                                    .read<CreateTransferBloc>()
                                    .add(CreateNewTransferEvent());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColorApp,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child:
                                  Text('Crear', style: TextStyle(color: white)),
                            ),
                          ],
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(size.width * 0.8, 40),
                        backgroundColor: primaryColorApp,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('CREAR TRANSFERENCIA',
                          style: TextStyle(color: white))),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
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
