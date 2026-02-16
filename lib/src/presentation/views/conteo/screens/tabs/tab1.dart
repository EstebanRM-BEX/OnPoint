// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';

class Tab1ScreenConteo extends StatelessWidget {
  const Tab1ScreenConteo({
    super.key,
    required this.ordenConteo,
  });

  final DatumConteo? ordenConteo;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<ConteoBloc, ConteoState>(
        listener: (context, state) {},
        builder: (context, state) {
          final ordeConteoBd = context.read<ConteoBloc>().ordenConteo;
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
                            child: Text(ordeConteoBd.name ?? '',
                                style: TextStyle(
                                    color: primaryColorApp,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Text('Almacen: ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp)),
                                Text(
                                  ordeConteoBd.warehouseName ?? "",
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
                                const Text('Tipo de conteo: ',
                                    style:  TextStyle(
                                        fontSize: 14, color: primaryColorApp)),
                                Text(
                                  ordeConteoBd.countType ?? "",
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
                               const Text('Tipo de filtro: ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp)),
                                Text(
                                  ordeConteoBd.filterType ?? "",
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
                               const Icon(
                                  Icons.calendar_month_sharp,
                                  color: primaryColorApp,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  ordeConteoBd.dateCount != null
                                      ? DateFormat('dd/MM/yyyy hh:mm ').format(
                                          DateTime.parse(ordeConteoBd.dateCount
                                                  .toString() ??
                                              ''))
                                      : "Sin fecha",
                                  style: const TextStyle(
                                      fontSize: 14, color: black),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                             const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Total lineas : ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp),
                                  )),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    ordeConteoBd.numeroLineas.toString(),
                                    style:
                                        const TextStyle(fontSize: 14, color: black),
                                  )),
                            ],
                          ),
                          Row(
                            children: [
                             const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Total lineas contadas : ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp),
                                  )),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context
                                        .read<ConteoBloc>()
                                        .lineasContadas
                                        .where((element) =>
                                            element.isDoneItem == 1)
                                        .toList()
                                        .length
                                        .toString(),
                                    style:
                                        const TextStyle(fontSize: 14, color: black),
                                  )),
                            ],
                          ),
                          Row(
                            children: [
                             const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Total ubicaciones : ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp),
                                  )),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context
                                        .read<ConteoBloc>()
                                        .ubicacionesConteo
                                        .length
                                        .toString(),
                                    style:
                                        const TextStyle(fontSize: 14, color: black),
                                  )),
                            ],
                          ),
                          Row(
                            children: [
                             const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Total categorias : ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp),
                                  )),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context
                                        .read<ConteoBloc>()
                                        .categoriasConteo
                                        .length
                                        .toString(),
                                    style:
                                       const TextStyle(fontSize: 14, color: black),
                                  )),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Text(
                                  'Observación:',
                                  style: TextStyle(
                                      fontSize: 12, color: primaryColorApp),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  ordeConteoBd.observationGeneral != null &&
                                          ordeConteoBd.observationGeneral != ""
                                      ? ordeConteoBd.observationGeneral!
                                      : 'Sin observación',
                                  style: const TextStyle(fontSize: 12, color: black),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                             const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Estado : ',
                                    style: TextStyle(
                                        fontSize: 14, color: primaryColorApp),
                                  )),
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    ordeConteoBd.numeroLineas ==
                                            context
                                                .read<ConteoBloc>()
                                                .lineasContadas
                                                .where((element) =>
                                                    element.isDoneItem == 1)
                                                .toList()
                                                .length
                                        ? 'Completado'
                                        : context
                                                .read<ConteoBloc>()
                                                .lineasContadas
                                                .where((element) =>
                                                    element.isDoneItem == 1)
                                                .toList()
                                                .isEmpty
                                            ? 'Pendiente'
                                            : 'En progreso',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: ordeConteoBd.numeroLineas ==
                                                context
                                                    .read<ConteoBloc>()
                                                    .lineasContadas
                                                    .where((element) =>
                                                        element.isDoneItem == 1)
                                                    .toList()
                                                    .length
                                            ? green
                                            : context
                                                    .read<ConteoBloc>()
                                                    .lineasContadas
                                                    .where((element) =>
                                                        element.isDoneItem == 1)
                                                    .toList()
                                                    .isEmpty
                                                ? red
                                                : yellow),
                                  )),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                               const Icon(
                                  Icons.person_rounded,
                                  color: primaryColorApp,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  ordeConteoBd.responsableName == false
                                      ? 'Sin responsable'
                                      : ordeConteoBd.responsableName == ''
                                          ? 'Sin responsable'
                                          : ordeConteoBd.responsableName ?? '',
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

                const SizedBox(height: 5),
                if (context.read<ConteoBloc>().ubicacionesConteo.isNotEmpty ==
                    true) ...[
                  Text(
                    'Ubicaciones de conteo',
                    style: TextStyle(
                        fontSize: 14,
                        color: primaryColorApp,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount:
                          context.read<ConteoBloc>().ubicacionesConteo.length,
                      itemBuilder: (context, index) {
                        return Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                  context
                                          .read<ConteoBloc>()
                                          .ubicacionesConteo[index]
                                          .name ??
                                      '',
                                  style: const TextStyle(
                                      fontSize: 12, color: black)),
                            ));
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                if (context.read<ConteoBloc>().categoriasConteo.isNotEmpty ==
                    true) ...[
                  Text(
                    'Categorias de conteo',
                    style: TextStyle(
                        fontSize: 14,
                        color: primaryColorApp,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount:
                          context.read<ConteoBloc>().categoriasConteo.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                                context
                                        .read<ConteoBloc>()
                                        .categoriasConteo[index]
                                        .name ??
                                    '',
                                style: const TextStyle(
                                    fontSize: 12, color: black)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // const Spacer(),
                // ElevatedButton(
                //     onPressed: () {},
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: primaryColorApp,
                //       minimumSize: Size(size.width * 0.9, 40),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(10),
                //       ),
                //       elevation: 3,
                //     ),
                //     child: Text('Terminar Recepcion',
                //         style: TextStyle(color: white))),
                // const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
