// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_batch_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/bloc/recepcion_batch_bloc.dart';

class Tab1ScreenRecepBatch extends StatelessWidget {
  const Tab1ScreenRecepBatch({
    super.key,
    required this.ordenCompra,
  });

  final ReceptionBatch? ordenCompra;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<RecepcionBatchBloc, RecepcionBatchState>(
        listener: (context, state) {},
        builder: (context, state) {
          final ordeCompraBd = context.read<RecepcionBatchBloc>().resultEntrada;

          final totalEnviadas = context
              .read<RecepcionBatchBloc>()
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(ordeCompraBd.name ?? '',
                                style: TextStyle(
                                    color: primaryColorApp,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
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
                                  ordeCompraBd.fechaCreacion != null
                                      ? DateFormat('dd/MM/yyyy hh:mm ').format(
                                          DateTime.parse(
                                              ordenCompra?.fechaCreacion ?? ''))
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
                                        TextStyle(fontSize: 12, color: black),
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
                                      : ordeCompraBd.responsable == ''
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
                                  ordeCompraBd.startTimeReception == null ||
                                          ordeCompraBd.startTimeReception == ''
                                      ? 'Sin tiempo'
                                      : ordeCompraBd.startTimeReception ?? "",
                                  style: const TextStyle(
                                      fontSize: 14, color: black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorApp,
                      minimumSize: Size(size.width * 0.9, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: Text('Terminar Recepcion',
                        style: TextStyle(color: white))),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
