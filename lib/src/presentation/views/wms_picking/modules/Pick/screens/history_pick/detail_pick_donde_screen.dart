import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/user/screens/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_done_id_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/screens/history_pick/index_list_pick__done_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/widgets/others/dialog_backorder_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class DetailPickDoneScreen extends StatelessWidget {
  final bool isFromPick;
  const DetailPickDoneScreen({super.key, required this.isFromPick});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
        backgroundColor: white,
        body: BlocConsumer<PickingPickBloc, PickingPickState>(
          listener: (context, state) {
            print("estado del listener $state");

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

            if (state is CreateBackOrderOrNotSuccess) {
              Navigator.pop(context);
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
                        context.read<PickingPickBloc>().add(
                            ValidateConfirmEvent(
                                context
                                        .read<PickingPickBloc>()
                                        .historyPickId
                                        ?.result
                                        ?.result
                                        ?.id ??
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
                      child: Text('Continuar', style: TextStyle(color: white)),
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
                      child: Text('Descartar', style: TextStyle(color: white)),
                    ),
                  ],
                );
              } else {
                showScrollableErrorDialog(state.error);
              }
            }
          },
          builder: (context, state) {
            final batch =
                context.read<PickingPickBloc>().historyPickId.result?.result;

            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: primaryColorApp,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
                      builder: (context, status) {
                    return Column(
                      children: [
                        const WarningWidgetCubit(),
                        Padding(
                          padding: EdgeInsets.only(
                              left: 10,
                              right: 10,
                              top: status != ConnectionStatus.online ? 20 : 20,
                              bottom: 10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back,
                                        color: white),
                                    onPressed: () {
                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  IndexListPickDoneScreen(
                                                    isFromPick: isFromPick,
                                                  )),
                                          (route) => false);
                                    },
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: size.width * 0.25),
                                    child: const Text(
                                      'DETALLES',
                                      style: TextStyle(
                                          color: white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                Card(
                  color: Colors.white,
                  elevation: 3,
                  child: ListTile(
                    title: Text(batch?.name ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color: primaryColorApp,
                            fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(batch?.zonaEntrega ?? '',
                                  style: const TextStyle(
                                      fontSize: 12, color: black)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Operación: ",
                                  style: TextStyle(
                                      fontSize: 12, color: primaryColorApp)),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                batch?.pickingType ?? '',
                                style: TextStyle(fontSize: 12, color: black),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Text('Estado: ',
                                  style: TextStyle(
                                      fontSize: 12, color: primaryColorApp)),
                              Text(
                                batch?.state == 'done'
                                    ? 'Completado'
                                    : batch?.state == 'draft'
                                        ? 'Borrador'
                                        : batch?.state == 'waiting'
                                            ? 'Esperando'
                                            : batch?.state == 'confirmed'
                                                ? 'Confirmado'
                                                : batch?.state == 'assigned'
                                                    ? 'Asignado'
                                                    : "",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: batch?.state == 'done'
                                      ? green
                                      : batch?.state == 'draft'
                                          ? grey
                                          : batch?.state == 'waiting'
                                              ? yellow
                                              : batch?.state == 'confirmed'
                                                  ? red
                                                  : batch?.state == 'assigned'
                                                      ? red
                                                      : black,
                                ),
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
                                      fontSize: 12, color: primaryColorApp)),
                              Text(
                                batch?.priority == '0'
                                    ? 'Normal'
                                    : 'Alta'
                                        "",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: batch?.priority == '0' ? black : red,
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
                                batch?.fechaCreacion.toString() ?? "Sin fecha",
                                style:
                                    const TextStyle(color: black, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: primaryColorApp,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  batch?.proveedor == ""
                                      ? "Sin contacto"
                                      : batch?.proveedor ?? '',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          batch?.proveedor == "" ? red : black),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt,
                                color: primaryColorApp,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "Doc. Origen: ",
                                style: TextStyle(fontSize: 12, color: black),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Expanded(
                                child: Text(
                                  batch?.origin.toString() ?? "Sin documento",
                                  style: TextStyle(
                                      fontSize: 12, color: primaryColorApp),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: batch?.backorderId != 0,
                          child: Row(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.file_copy,
                                    color: primaryColorApp, size: 15),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(batch?.backorderName ?? '',
                                  style: TextStyle(
                                      color: black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                color: primaryColorApp,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "Cantidad unidades enviadas: ",
                                style: TextStyle(fontSize: 12, color: black),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Expanded(
                                child: Text(
                                  batch?.quantityOrdered.toString() ?? "0",
                                  style: TextStyle(
                                      fontSize: 12, color: primaryColorApp),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                color: primaryColorApp,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "Cantidad unidades solicitadas: ",
                                style: TextStyle(fontSize: 12, color: black),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Expanded(
                                child: Text(
                                  batch?.quantityDone.toString() ?? "0",
                                  style: TextStyle(
                                      fontSize: 12, color: primaryColorApp),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: primaryColorApp,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  batch?.responsable == ""
                                      ? "Sin responsable"
                                      : batch?.responsable ?? '',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: batch?.responsable == ""
                                          ? red
                                          : black),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              batch?.startTimeTransfer != ""
                                  ? GestureDetector(
                                      onTap: () {
                                        showDialog(
                                            context: context,
                                            builder: (context) => DialogInfo(
                                                  title: 'Tiempo de inicio',
                                                  body:
                                                      'Este Pick fue iniciado a las ${batch?.startTimeTransfer}',
                                                ));
                                      },
                                      child: Icon(
                                        Icons.timer_sharp,
                                        color: primaryColorApp,
                                        size: 15,
                                      ),
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                //btn para validar el pick
                Visibility(
                  visible:
                      batch?.state == 'confirmed' || batch?.state == 'assigned',
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(size.width * 0.9, 40),
                      backgroundColor: primaryColorApp,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    onPressed: () {
                      final unidadesSeparadas =
                          calcularUnidadesSeparadas(batch!);

                      print("unidades $unidadesSeparadas");
                      showDialog(
                          context: Navigator.of(context, rootNavigator: true)
                              .context,
                          builder: (context) {
                            return DialogBackorderPick(
                              isHistory: true,
                              idPick: batch.id ?? 0,
                              unidadesSeparadas:
                                  double.parse(unidadesSeparadas),
                              createBackorder: batch.createBackorder ?? "ask",
                              isExternalProduct: true,
                            );
                          });
                    },
                    child: const Text(
                      'VALIDAR PICK',
                      style: TextStyle(
                          color: white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                //LISTA DE LINEAS
                if (batch?.lineasTransferenciaEnviadas?.isNotEmpty ??
                    false) ...[
                  Center(
                      child: Text(
                    'Productos enviados',
                    style: TextStyle(color: primaryColorApp),
                  )),

                  Expanded(
                    child: Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: EdgeInsets.only(bottom: 15),
                        child: ListView.builder(
                            padding: EdgeInsets.only(
                                top: 10, bottom: size.height * 0.15),
                            shrinkWrap: true,
                            physics: const ScrollPhysics(),
                            itemCount:
                                batch?.lineasTransferenciaEnviadas?.length ?? 0,
                            itemBuilder: (context, index) {
                              return Card(
                                  color: white,
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            batch
                                                    ?.lineasTransferenciaEnviadas?[
                                                        index]
                                                    .productId?[1]
                                                    .toString() ??
                                                '',
                                            style: TextStyle(
                                                fontSize: 12, color: black),
                                          ),
                                        ),
                                        Visibility(
                                          visible: batch
                                                  ?.lineasTransferenciaEnviadas?[
                                                      index]
                                                  .productTracking !=
                                              'none',
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'Lote : ',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            primaryColorApp), // Color rojo para la primera parte
                                                  ),
                                                  TextSpan(
                                                    text: batch
                                                            ?.lineasTransferenciaEnviadas?[
                                                                index]
                                                            .lote
                                                            .toString() ??
                                                        '',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            black), // Color negro para el valor
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: 'Cantidad : ',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp), // Color rojo para la primera parte
                                                    ),
                                                    TextSpan(
                                                      text: batch
                                                              ?.lineasTransferenciaEnviadas?[
                                                                  index]
                                                              .quantity
                                                              .toString() ??
                                                          '',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              black), // Color negro para el valor
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          'Cantidad separada : ',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp), // Color rojo para la primera parte
                                                    ),
                                                    TextSpan(
                                                      text: (batch
                                                                  ?.lineasTransferenciaEnviadas?[
                                                                      index]
                                                                  .quantityDone ??
                                                              0.0)
                                                          .toString(),
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              black), // Color negro para el valor
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      'Tiempo de separacion : ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          primaryColorApp), // Color rojo para la primera parte
                                                ),
                                                TextSpan(
                                                  text: batch
                                                          ?.lineasTransferenciaEnviadas?[
                                                              index]
                                                          .time
                                                          .toString() ??
                                                      '',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          black), // Color negro para el valor
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'Observacion : ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          primaryColorApp), // Color rojo para la primera parte
                                                ),
                                                TextSpan(
                                                  text: batch
                                                          ?.lineasTransferenciaEnviadas?[
                                                              index]
                                                          .observation
                                                          .toString() ??
                                                      '',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          black), // Color negro para el valor
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'Ubicacion destino : ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          primaryColorApp), // Color rojo para la primera parte
                                                ),
                                                TextSpan(
                                                  text: batch
                                                          ?.lineasTransferenciaEnviadas?[
                                                              index]
                                                          .locationDestName
                                                          .toString() ??
                                                      '',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          black), // Color negro para el valor
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ));
                            })),
                  ),

                  // ignore: prefer_is_empty
                ],
                if (batch?.lineasTransferencia?.isNotEmpty ?? false) ...[
                  const Center(
                      child: Text(
                    'Productos no enviados',
                    style: TextStyle(color: primaryColorApp),
                  )),
                  Expanded(
                    child: Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: EdgeInsets.only(bottom: 15),
                        child: ListView.builder(
                            padding: EdgeInsets.only(
                                top: 10, bottom: size.height * 0.15),
                            shrinkWrap: true,
                            physics: const ScrollPhysics(),
                            itemCount: batch?.lineasTransferencia?.length ?? 0,
                            itemBuilder: (context, index) {
                              return Card(
                                  color: white,
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            batch?.lineasTransferencia?[index]
                                                    .productId?[1]
                                                    .toString() ??
                                                '',
                                            style: TextStyle(
                                                fontSize: 12, color: black),
                                          ),
                                        ),
                                        Visibility(
                                          visible: batch
                                                  ?.lineasTransferencia?[index]
                                                  .productTracking !=
                                              'none',
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'Lote : ',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            primaryColorApp), // Color rojo para la primera parte
                                                  ),
                                                  TextSpan(
                                                    text: batch
                                                            ?.lineasTransferencia?[
                                                                index]
                                                            .lote
                                                            .toString() ??
                                                        '',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            black), // Color negro para el valor
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'Cantidad : ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          primaryColorApp), // Color rojo para la primera parte
                                                ),
                                                TextSpan(
                                                  text: batch
                                                          ?.lineasTransferencia?[
                                                              index]
                                                          .quantity
                                                          .toString() ??
                                                      '',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          black), // Color negro para el valor
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'Ubicacion destino : ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          primaryColorApp), // Color rojo para la primera parte
                                                ),
                                                TextSpan(
                                                  text: batch
                                                          ?.lineasTransferencia?[
                                                              index]
                                                          .locationDestName
                                                          .toString() ??
                                                      '',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          black), // Color negro para el valor
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ));
                            })),
                  ),
                ],
              ],
            );
          },
        ));
  }

  String calcularUnidadesSeparadas(ResultResult batch) {
    try {
      final progress = (batch.quantityDone / batch.quantityOrdered) * 100;
      return progress.toStringAsFixed(2);
    } catch (e, s) {
      print("❌ Error en el calcularUnidadesSeparadas $e ->$s");
      return '';
    }
  }
}
