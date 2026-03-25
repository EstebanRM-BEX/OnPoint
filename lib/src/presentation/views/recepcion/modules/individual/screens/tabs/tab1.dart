// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class Tab1ScreenRecep extends StatelessWidget {
  const Tab1ScreenRecep({
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
          if (state is SendTemperatureLoading) {
            showDialog(
              context: context,
              builder: (context) {
                return const DialogLoading(
                  message: "Enviando temperatura...",
                );
              },
            );
          }

          if (state is SendTemperatureSuccess) {
            Navigator.pop(context);
            Get.snackbar("360 Software Informa", state.message,
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: Icon(Icons.error, color: Colors.green));
          }

          if (state is SendTemperatureFailure) {
            Navigator.pop(context);
            Get.snackbar("360 Software Informa", state.error,
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: Icon(Icons.error, color: Colors.red));
          }

          debugPrint("State: $state");
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

          if (state is CreateBackOrderOrNotFailure) {
            Navigator.pop(context);
            showScrollableErrorDialog(state.error);
          }

          if (state is CreateBackOrderOrNotSuccess) {
            Get.snackbar("360 Software Informa", state.message,
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: Icon(Icons.error, color: Colors.green));
            Navigator.pop(context);

            if (ordenCompra?.type == 'dev') {
              Navigator.pushReplacementNamed(
                context,
                'list-devoluciones',
              );
            } else {
              Navigator.pushReplacementNamed(
                context,
                'list-ordenes-compra',
              );
            }
          }
        },
        builder: (context, state) {
          final ordeCompraBd = context.read<RecepcionBloc>().resultEntrada;

          final totalEnviadas = context
              .read<RecepcionBloc>()
              .listProductsEntrada
              .map((e) => e.quantityDone ?? 0)
              .fold<double>(0, (a, b) => a + b);

          return Scaffold(
            backgroundColor: white,
            body: Column(
              children: [
                //*detalles del batch
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  width: double.infinity,
                  child: Card(
                    color: Colors.white,
                    elevation: 5,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(ordeCompraBd.name ?? '',
                                    style: TextStyle(
                                        color: primaryColorApp,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ),
                              //icno de desplegar
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  context.read<RecepcionBloc>().add(
                                      ToggleProductExpansionEvent(!context
                                          .read<RecepcionBloc>()
                                          .isExpanded));
                                },
                                icon: Icon(
                                  !context.read<RecepcionBloc>().isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: primaryColorApp,
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text('Tipo de entrada: ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp)),
                                Text(
                                  ordeCompraBd.pickingType ?? "",
                                  style: const TextStyle(
                                      fontSize: 14, color: black),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text('Prioridad: ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp)),
                                Text(
                                  ordeCompraBd.priority == '0'
                                      ? 'Normal'
                                      : 'Alta'
                                          "",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ordeCompraBd.priority == '0'
                                        ? black
                                        : red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text('Propietario: ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp)),
                                Text(
                                  ordeCompraBd.propietario == ''
                                      ? 'Sin propietario'
                                      : ordeCompraBd.propietario ?? "",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ordeCompraBd.priority == ''
                                        ? black
                                        : red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: black,
                            thickness: 1,
                            height: 5,
                          ),
                          if (!context.read<RecepcionBloc>().isExpanded) ...[
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
                                    ordeCompraBd.fechaCreacion != null
                                        ? DateFormat('dd/MM/yyyy hh:mm ')
                                            .format(DateTime.parse(
                                                ordenCompra?.fechaCreacion ??
                                                    ''))
                                        : "Sin fecha",
                                    style: const TextStyle(
                                        fontSize: 14, color: black),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(ordeCompraBd.proveedor ?? '',
                                  style: TextStyle(
                                    color: black,
                                    fontSize: 14,
                                  )),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.shopping_cart_sharp,
                                    color: primaryColorApp,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    ordeCompraBd.purchaseOrderName == ""
                                        ? 'Sin orden de compra'
                                        : ordeCompraBd.purchaseOrderName ?? '',
                                    style: const TextStyle(
                                        fontSize: 14, color: black),
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible: ordeCompraBd.backorderId != 0,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.file_copy,
                                    color: primaryColorApp,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 5),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        ordeCompraBd.backorderName ?? '',
                                        style: TextStyle(
                                            color: black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Peso: ',
                                      style: TextStyle(
                                          fontSize: 14, color: primaryColorApp),
                                    )),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    // Formateamos el número a 2 decimales
                                    NumberFormat('0.00')
                                        .format(ordeCompraBd.pesoTotal ?? 0),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: black,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Total productos : ',
                                      style: TextStyle(
                                          fontSize: 14, color: primaryColorApp),
                                    )),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      ordeCompraBd.numeroLineas.toString(),
                                      style:
                                          TextStyle(fontSize: 14, color: black),
                                    )),
                              ],
                            ),
                            Visibility(
                              visible: context
                                      .read<RecepcionBloc>()
                                      .configurations
                                      .result
                                      ?.result
                                      ?.hideExpectedQty ==
                                  false,
                              child: Row(
                                children: [
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Total de unidades: ',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: primaryColorApp),
                                      )),
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        ordeCompraBd.numeroItems.toString(),
                                        style: TextStyle(
                                            fontSize: 14, color: black),
                                      )),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Unidades recibidas: ',
                                      style: TextStyle(
                                          fontSize: 14, color: primaryColorApp),
                                    )),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      totalEnviadas.toString(),
                                      style:
                                          TextStyle(fontSize: 14, color: black),
                                    )),
                              ],
                            ),
                            Row(
                              children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Temperatura: ',
                                      style: TextStyle(
                                          fontSize: 14, color: primaryColorApp),
                                    )),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      ordeCompraBd.manejaTemperatura == 1
                                          ? (ordeCompraBd.temperatura == 0.0
                                              ? 'Sin temperatura'
                                              : '${ordeCompraBd.temperatura} °C')
                                          : 'No aplica',
                                      style:
                                          TextStyle(fontSize: 14, color: black),
                                    )),
                              ],
                            ),
                            Row(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Destino: ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    ordeCompraBd.locationDestName ?? '',
                                    style: const TextStyle(
                                        fontSize: 14, color: black),
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
                                    ordeCompraBd.responsable == false
                                        ? 'Sin responsable'
                                        : ordeCompraBd.responsable ?? '',
                                    style: const TextStyle(
                                        fontSize: 14, color: black),
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
                                        fontSize: 14, color: primaryColorApp),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    ordeCompraBd.startTimeReception ?? "",
                                    style: const TextStyle(
                                        fontSize: 14, color: black),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // const Spacer(),
//btn de imprimir
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 20),
                //   child: ElevatedButton(
                //       onPressed: () {
                //         ModalPrintersList.show(context);
                //       },
                //       style: ElevatedButton.styleFrom(
                //         minimumSize: Size(size.width * 0.9, 40),
                //         backgroundColor: primaryColorApp,
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(10),
                //         ),
                //       ),
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         children: [
                //           Icon(Icons.print, color: white),
                //           const SizedBox(width: 5),
                //           Text('Imprimir', style: TextStyle(color: white)),
                //         ],
                //       )),
                // ),

                Visibility(
                  visible: context
                          .read<RecepcionBloc>()
                          .configurations
                          .result
                          ?.result
                          ?.hideValidateReception ==
                      false,
                  child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: AlertDialog(
                                  backgroundColor: Colors.white,
                                  actionsAlignment: MainAxisAlignment.center,
                                  title: Text(
                                    (ordenCompra?.type == 'dev')
                                        ? 'Confirmar Devolución'
                                        : 'Confirmar Recepcion',
                                    style: TextStyle(
                                        color: primaryColorApp, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 100,
                                        width: 200,
                                        child: SvgPicture.asset(
                                          "assets/images/icono.svg",
                                          height: 150,
                                          width: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          (totalEnviadas ==
                                                  ordeCompraBd.numeroItems)
                                              ? (ordenCompra?.type == 'dev')
                                                  ? '¿Estás seguro de confirmar la devolución y dejarla lista para ser enviada?'
                                                  : '¿Estás seguro de confirmar la transferencia y dejarla lista para ser enviada?'
                                              : ordeCompraBd.createBackorder ==
                                                      "never"
                                                  ? (ordenCompra?.type == 'dev')
                                                      ? '¿Estás seguro de confirmar la devolución y dejarla lista para ser enviada?'
                                                      : '¿Estás seguro de confirmar la transferencia y dejarla lista para ser enviada?'
                                                  : "Usted ha procesado cantidades de productos menores que los requeridos en el movimiento orignal.",
                                          style: TextStyle(
                                              color: black, fontSize: 14),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    Visibility(
                                      visible: (totalEnviadas !=
                                              ordeCompraBd.numeroItems)
                                          ? ordeCompraBd.createBackorder ==
                                                      "never" ||
                                                  ordeCompraBd
                                                          .createBackorder ==
                                                      "always"
                                              ? false
                                              : true
                                          : false,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.read<RecepcionBloc>().add(
                                              CreateBackOrderOrNot(
                                                  ordenCompra?.type ?? '',
                                                  ordeCompraBd.id ?? 0,
                                                  true));
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColorApp,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          minimumSize:
                                              Size(size.width * 0.9, 40),
                                        ),
                                        child: const Text(
                                          'Confirmar y Crear un Backorder',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        context.read<RecepcionBloc>().add(
                                            CreateBackOrderOrNot(
                                                ordenCompra?.type ?? '',
                                                ordeCompraBd.id ?? 0,
                                                ordeCompraBd.createBackorder ==
                                                        "never"
                                                    ? false
                                                    : ordeCompraBd
                                                                .createBackorder ==
                                                            "always"
                                                        ? true
                                                        : false));
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColorApp,
                                        minimumSize: Size(size.width * 0.9, 40),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        (ordenCompra?.type == 'dev')
                                            ? 'Confirmar Devolución'
                                            : 'Confirmar Recepcion',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size(size.width * 0.9, 40),
                                        backgroundColor: grey,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancelar',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorApp,
                        minimumSize: Size(size.width * 0.9, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                          (ordenCompra?.type == 'dev')
                              ? 'TERMINAR DEVOLUCIÓN'
                              : 'TERMINAR RECEPCIÓN',
                          style: TextStyle(color: white))),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
