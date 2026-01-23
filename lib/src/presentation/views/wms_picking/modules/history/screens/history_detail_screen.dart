import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/wms_picking/bloc/wms_picking_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/history/screens/list_batchs_history_screen.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocBuilder<WMSPickingBloc, PickingState>(
      builder: (context, state) {
        final batch = context.read<WMSPickingBloc>().historyBatchId;

        return Scaffold(
          backgroundColor: white,
          body: Column(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: white),
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const HistoryListScreen()),
                                        (route) => false);
                                  },
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.only(left: size.width * 0.25),
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                    color: white,
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              batch.name ?? '',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: black),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Zona entrega : ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            primaryColorApp), // Color rojo para la primera parte
                                  ),
                                  TextSpan(
                                    text: batch.zonaEntrega ?? '',
                                    style: TextStyle(
                                        fontSize: 14,
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
                                    text: 'Responsable : ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            primaryColorApp), // Color rojo para la primera parte
                                  ),
                                  TextSpan(
                                    text: batch.userName ?? '',
                                    style: TextStyle(
                                        fontSize: 14,
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
                                    text: 'Estado : ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            primaryColorApp), // Color rojo para la primera parte
                                  ),
                                  TextSpan(
                                    text: batch.state == 'in_progress'
                                        ? 'Proceso'
                                        : 'Listo',
                                    style: TextStyle(
                                        fontSize: 14,
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
                                    text: 'Tipo de operación : ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            primaryColorApp), // Color rojo para la primera parte
                                  ),
                                  TextSpan(
                                    text: batch.pickingTypeId ?? '',
                                    style: TextStyle(
                                        fontSize: 14,
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
                                    text: 'Ubicación destino : ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            primaryColorApp), // Color rojo para la primera parte
                                  ),
                                  TextSpan(
                                    text: batch.muelle ?? '',
                                    style: TextStyle(
                                        fontSize: 14,
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
                                    text: 'Total productos : ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            primaryColorApp), // Color rojo para la primera parte
                                  ),
                                  TextSpan(
                                    text: batch.countItems.toString(),
                                    style: TextStyle(
                                        fontSize: 14,
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
                                    text: 'Total unidades : ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            primaryColorApp), // Color rojo para la primera parte
                                  ),
                                  TextSpan(
                                    text: batch.totalQuantityItems.toString(),
                                    style: TextStyle(
                                        fontSize: 14,
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
                                    text: 'Unidades separadas : ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            primaryColorApp), // Color rojo para la primera parte
                                  ),
                                  TextSpan(
                                    text: batch.itemsSeparado.toString(),
                                    style: TextStyle(
                                        fontSize: 14,
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
                                    text: 'Inicio de proceso : ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            primaryColorApp), // Color rojo para la primera parte
                                  ),
                                  TextSpan(
                                    text: batch.startTimePick ?? "",
                                    style: TextStyle(
                                        fontSize: 14,
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
                                    text: 'Fin de proceso : ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            primaryColorApp), // Color rojo para la primera parte
                                  ),
                                  TextSpan(
                                    text: batch.endTimePick ?? "",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            black), // Color negro para el valor
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ),
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
                       physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: batch.listItems?.length ?? 0,
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
                                        batch.listItems?[index].productId?[1]
                                                .toString() ??
                                            '',
                                        style: TextStyle(
                                            fontSize: 12, color: black),
                                      ),
                                    ),
                                    Align(
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
                                              text: batch.listItems?[index]
                                                      .lotId?[1]
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
                                                  text: batch.listItems?[index]
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
                                                  text: 'Cantidad separada : ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          primaryColorApp), // Color rojo para la primera parte
                                                ),
                                                TextSpan(
                                                  text: (batch.listItems?[index]
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
                                              text: 'Tiempo de separacion : ',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      primaryColorApp), // Color rojo para la primera parte
                                            ),
                                            TextSpan(
                                              text: batch.listItems?[index]
                                                      .timeLine
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
                                              text: batch.listItems?[index]
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
                                              text: batch.listItems?[index]
                                                      .locationDestId?[1]
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
              )
            ],
          ),
        );
      },
    );
  }
}
