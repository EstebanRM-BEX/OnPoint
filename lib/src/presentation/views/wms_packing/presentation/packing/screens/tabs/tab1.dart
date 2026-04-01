// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/widgets/others/dialog_backorder_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class Tab1PedidoScreen extends StatelessWidget {
  const Tab1PedidoScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocBuilder<PackingPedidoBloc, PackingPedidoState>(
        builder: (context, state) {
          final totalEnviadas = context
              .read<PackingPedidoBloc>()
              .productsDonePacking
              .map((e) => e.quantity ?? 0)
              .fold<double>(0, (a, b) => a + b);

          final pedidoCurrent =
              context.read<PackingPedidoBloc>().currentPedidoPack;
          return BlocListener<PackingPedidoBloc, PackingPedidoState>(
            listener: (context, state) {
              debugPrint('STATE : $state');

              if (state is CreateBackOrderOrNotSuccess) {
                if (state.isBackorder) {
                  Get.snackbar("360 Software Informa", state.msg,
                      backgroundColor: white,
                      colorText: primaryColorApp,
                      icon: Icon(Icons.error, color: Colors.green));
                } else {
                  Get.snackbar("360 Software Informa", state.msg,
                      backgroundColor: white,
                      colorText: primaryColorApp,
                      icon: Icon(Icons.error, color: Colors.green));
                }
                Navigator.pushReplacementNamed(
                  context,
                  'list-packing',
                );
              }

              if (state is CreateBackOrderOrNotLoading) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const DialogLoading(
                      message: "Validando informacion...",
                    );
                  },
                );
              }

              if (state is ValidateConfirmLoading) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const DialogLoading(
                      message: "Validando informacion...",
                    );
                  },
                );
              }

              if (state is ValidateConfirmSuccess) {
                //volvemos a llamar las entradas que tenemos guardadas en la bd
                if (state.isBackorder) {
                  Get.snackbar("360 Software Informa", state.msg,
                      backgroundColor: white,
                      colorText: primaryColorApp,
                      icon: Icon(Icons.error, color: Colors.green));
                } else {
                  Get.snackbar("360 Software Informa", state.msg,
                      backgroundColor: white,
                      colorText: primaryColorApp,
                      icon: Icon(Icons.error, color: Colors.green));
                }

                Navigator.pushReplacementNamed(
                  context,
                  'list-packing',
                );
              }

              if (state is ValidateConfirmFailure) {
                Navigator.pop(context);

                showScrollableErrorDialog(state.error);
              }

              if (state is CreateBackOrderOrNotFailure) {
                Navigator.pop(context);

                if (state.error.contains('expiry.picking.confirmation')) {
                  Get.defaultDialog(
                    title: '360 Software Informa',
                    titleStyle: TextStyle(color: Colors.red, fontSize: 18),
                    middleText:
                        'Algunos productos tienen fecha de caducidad alcanzada.\n¿Desea continuar con la confirmacion aceptando los productos vencidos?',
                    middleTextStyle: TextStyle(color: black, fontSize: 14),
                    backgroundColor: Colors.white,
                    radius: 10,
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          context.read<PackingPedidoBloc>().add(
                              ValidateConfirmEvent(
                                  context
                                          .read<PackingPedidoBloc>()
                                          .currentPedidoPack
                                          .id ??
                                      0,
                                  state.isBackorder,
                                  false));

                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColorApp,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            Text('Continuar', style: TextStyle(color: white)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            Text('Descartar', style: TextStyle(color: white)),
                      ),
                    ],
                  );
                } else {
                  showScrollableErrorDialog(state.error);
                }
              }
            },
            child: Scaffold(
              backgroundColor: white,
              body: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Header con título y botón
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  pedidoCurrent.name ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryColorApp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    context.read<PackingPedidoBloc>().viewDetail
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                    color: primaryColorApp,
                                  ),
                                  onPressed: () {
                                    context.read<PackingPedidoBloc>().add(
                                        ShowDetailvent(context
                                            .read<PackingPedidoBloc>()
                                            .viewDetail));
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  iconSize: 24,
                                ),
                              ],
                            ),

                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text('Prioridad: ',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: primaryColorApp)),
                                        Text(
                                          pedidoCurrent.priority == '0'
                                              ? 'Normal'
                                              : 'Alta'
                                                  "",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: pedidoCurrent.priority == '0'
                                                ? black
                                                : red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Operacion: ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: primaryColorApp),
                                      ),
                                      Text(
                                        pedidoCurrent.pickingType ?? "",
                                        style: TextStyle(
                                            fontSize: 12, color: black),
                                      ),
                                    ],
                                  ),
                                  if (pedidoCurrent.observacion != null &&
                                      pedidoCurrent
                                          .observacion!.isNotEmpty) ...[
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text("Observación: ",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp)),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        pedidoCurrent.observacion.toString(),
                                        style: TextStyle(
                                            fontSize: 12, color: black),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  Row(
                                    children: [
                                      Text(
                                        'Referencia: ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: primaryColorApp),
                                      ),
                                      Text(
                                        pedidoCurrent.referencia ?? '',
                                        style: TextStyle(
                                            fontSize: 12, color: black),
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    color: black,
                                    thickness: 1,
                                    height: 5,
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month_sharp,
                                          color: primaryColorApp,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          pedidoCurrent.fechaCreacion != null
                                              ? DateFormat('dd/MM/yyyy hh:mm ')
                                                  .format(DateTime.parse(
                                                      pedidoCurrent
                                                          .fechaCreacion
                                                          .toString()))
                                              : "Sin fecha",
                                          style: const TextStyle(
                                              fontSize: 12, color: black),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      pedidoCurrent.proveedor == "" ||
                                              pedidoCurrent.proveedor == null
                                          ? 'Sin proveedor'
                                          : pedidoCurrent.proveedor ?? "",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              pedidoCurrent.proveedor == "" ||
                                                      pedidoCurrent.proveedor ==
                                                          null
                                                  ? red
                                                  : primaryColorApp),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Contacto: ',
                                      style: TextStyle(
                                          fontSize: 12, color: primaryColorApp),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      pedidoCurrent.contactoName == "" ||
                                              pedidoCurrent.contactoName == null
                                          ? 'Sin contacto'
                                          : pedidoCurrent.contactoName ?? "",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: pedidoCurrent.contactoName ==
                                                      "" ||
                                                  pedidoCurrent.contactoName ==
                                                      null
                                              ? red
                                              : black),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Total productos : ',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: primaryColorApp),
                                          )),
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            pedidoCurrent.numeroLineas
                                                .toString(),
                                            style: TextStyle(
                                                fontSize: 12, color: black),
                                          )),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Total de unidades: ',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: primaryColorApp),
                                          )),
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            pedidoCurrent.numeroItems
                                                .toString(),
                                            style: TextStyle(
                                                fontSize: 12, color: black),
                                          )),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Total productos empacados: ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: primaryColorApp),
                                      ),
                                      Text(
                                        context
                                            .read<PackingPedidoBloc>()
                                            .listOfProductos
                                            .where((element) =>
                                                element.isPackage == 1)
                                            .length
                                            .toString(),
                                        style: TextStyle(
                                            fontSize: 12, color: black),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Numero de paquetes: ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: primaryColorApp),
                                      ),
                                      Text(
                                        context
                                            .read<PackingPedidoBloc>()
                                            .packages
                                            .length
                                            .toString(),
                                        style: TextStyle(
                                            fontSize: 12, color: black),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Destino: ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          pedidoCurrent.locationDestName ?? '',
                                          style: const TextStyle(
                                              fontSize: 12, color: black),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_rounded,
                                          color: primaryColorApp,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          pedidoCurrent.responsable == false
                                              ? 'Sin responsable'
                                              : pedidoCurrent.responsable ?? '',
                                          style: const TextStyle(
                                              fontSize: 12, color: black),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          color: primaryColorApp,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Tiempo de inicio : ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: primaryColorApp),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          pedidoCurrent.startTimeTransfer ?? "",
                                          style: const TextStyle(
                                              fontSize: 12, color: black),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Visibility(
                                    visible: pedidoCurrent.isTerminate != 1 &&
                                        (context
                                                    .read<PackingPedidoBloc>()
                                                    .configurations
                                                    .result // Asumo que .configurations existe
                                                    ?.result
                                                    ?.hideValidatePacking ??
                                                false) ==
                                            false,
                                    child: ElevatedButton(
                                        onPressed: () {
                                          if (context
                                              .read<PackingPedidoBloc>()
                                              .productsDone
                                              .isNotEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'No se puede confirmar un pedido con productos en proceso o listos para empaquetar',
                                                  style:
                                                      TextStyle(color: white),
                                                ),
                                                backgroundColor:
                                                    Colors.red[200],
                                              ),
                                            );
                                            return;
                                          }
                                          if (context
                                              .read<PackingPedidoBloc>()
                                              .packages
                                              .isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'No se puede confirmar un pedido sin empaques',
                                                  style:
                                                      TextStyle(color: white),
                                                ),
                                                backgroundColor:
                                                    Colors.red[200],
                                              ),
                                            );
                                            return;
                                          }

                                          final progress = (totalEnviadas /
                                                      context
                                                          .read<
                                                              PackingPedidoBloc>()
                                                          .currentPedidoPack
                                                          .numeroItems ??
                                                  0) *
                                              100;

                                          showDialog(
                                              context: Navigator.of(context,
                                                      rootNavigator: true)
                                                  .context,
                                              builder: (context) {
                                                return DialogBackorderPack(
                                                  totalEnviadas: progress,
                                                  createBackorder: context
                                                          .read<
                                                              PackingPedidoBloc>()
                                                          .currentPedidoPack
                                                          .createBackorder ??
                                                      "ask",
                                                );
                                              });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: Size(
                                            size.width * 0.9,
                                            30, // Alto
                                          ),
                                          backgroundColor: primaryColorApp,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'Confirmar pedido',
                                          style: TextStyle(
                                              color: white, fontSize: 12),
                                        )),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
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
}
