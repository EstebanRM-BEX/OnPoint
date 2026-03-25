import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class ListConteoScreen extends StatelessWidget {
  const ListConteoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<ConteoBloc, ConteoState>(
        listener: (context, state) {
          if (state is NeedUpdateVersionState) {
            Get.snackbar(
              '360 Software Informa',
              'Hay una nueva versión disponible. Actualiza desde la configuración de la app, pulsando el nombre de usuario en el Home',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.amber),
              showProgressIndicator: true,
              duration: Duration(seconds: 5),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
              backgroundColor: primaryColorApp,
              body: SafeArea(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      //appBar
                      Container(
                        decoration: const BoxDecoration(
                          color: primaryColorApp,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        width: double.infinity,
                        child: BlocBuilder<ConnectionStatusCubit,
                            ConnectionStatus>(builder: (context, status) {
                          return Column(
                            children: [
                              const WarningWidgetCubit(),
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: 5,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back,
                                          size: 20, color: white),
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/home',
                                        );
                                      },
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        context.read<ConteoBloc>().add(
                                              GetConteosEvent(),
                                            );
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            left: size.width * 0.18),
                                        child: Row(
                                          children: [
                                            const Text("CONTEO FISICO",
                                                style: TextStyle(
                                                    color: white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18)),
                                            const SizedBox(width: 5),
                                            Icon(Icons.refresh,
                                                color: white, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    //todo menu de opciones de filtros, all, donde, pending, in progress
                                    PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            size: 20, color: white),
                                        onSelected: (String value) {
                                          debugPrint(
                                              'Filtro seleccionado: $value');
                                          context.read<ConteoBloc>().add(
                                                OrderConteosByStateEvent(value),
                                              );
                                        },
                                        itemBuilder: (BuildContext context) => [
                                              const PopupMenuItem<String>(
                                                value: 'all',
                                                child: Text(
                                                  'Todos',
                                                  style: TextStyle(
                                                      color: black,
                                                      fontSize: 12),
                                                ),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'pending',
                                                child: Text(
                                                  'Pendiente',
                                                  style: TextStyle(
                                                      color: black,
                                                      fontSize: 12),
                                                ),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'in_progress',
                                                child: Text(
                                                  'En progreso',
                                                  style: TextStyle(
                                                      color: black,
                                                      fontSize: 12),
                                                ),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'done',
                                                child: Text(
                                                  'Completado',
                                                  style: TextStyle(
                                                      color: black,
                                                      fontSize: 12),
                                                ),
                                              ),
                                            ]),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),

                      (context.read<ConteoBloc>().ordenesDeConteo?.isEmpty ??
                              true)
                          ? Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Text('No hay conteos disponibles',
                                      style:
                                          TextStyle(fontSize: 14, color: grey)),
                                  const Text('Intente nuevamente más tarde',
                                      style:
                                          TextStyle(fontSize: 12, color: grey)),
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
                                  padding: const EdgeInsets.only(top: 10),
                                  itemCount: context
                                      .read<ConteoBloc>()
                                      .ordenesDeConteo
                                      ?.length,
                                  itemBuilder:
                                      (BuildContext contextList, int index) {
                                    final conteo = context
                                        .read<ConteoBloc>()
                                        .ordenesDeConteo?[index];
                                    return Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            context.read<ConteoBloc>().add(
                                                  LoadConteoAndProductsEvent(
                                                      ordenConteoId:
                                                          conteo?.id ?? 0),
                                                );
                                            Navigator.pushReplacementNamed(
                                              context,
                                              'conteo-detail',
                                              arguments: [
                                                0,
                                                conteo,
                                              ],
                                            );
                                            debugPrint(
                                                'orden id: ${conteo?.toJson()}');
                                          },
                                          child: Card(
                                            elevation: 3,
                                            child: ListTile(
                                              trailing: const Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: primaryColorApp),
                                              title: Text(conteo?.name ?? '',
                                                  style: TextStyle(
                                                      color: primaryColorApp,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              subtitle: Column(
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Row(
                                                      children: [
                                                        const Text(
                                                          'Estado:',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: black),
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        Text(
                                                          // LÓGICA DEL TEXTO
                                                          (conteo?.numeroLineas ==
                                                                  0)
                                                              ? 'En progreso' // 1. Nueva validación: Si no hay líneas definidas
                                                              : (conteo?.numeroLineas ==
                                                                      conteo
                                                                          ?.numeroItemsContados)
                                                                  ? 'Completado' // 2. Si son iguales (y no son cero ambos)
                                                                  : (conteo?.numeroItemsContados ==
                                                                          0)
                                                                      ? 'Pendiente' // 3. Si no ha contado nada
                                                                      : 'En progreso', // 4. Cualquier otro caso (está contando)

                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            // LÓGICA DEL COLOR (Debe seguir el mismo orden)
                                                            color: (conteo
                                                                        ?.numeroLineas ==
                                                                    0)
                                                                ? yellow // Color para nueva validación
                                                                : (conteo?.numeroLineas ==
                                                                        conteo
                                                                            ?.numeroItemsContados)
                                                                    ? green
                                                                    : (conteo?.numeroItemsContados ==
                                                                            0)
                                                                        ? red
                                                                        : yellow,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Row(
                                                        children: [
                                                          const Text(
                                                            'Tipo de conteo:',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: black),
                                                          ),
                                                          const SizedBox(
                                                              width: 5),
                                                          Text(
                                                            conteo?.countType ??
                                                                'Sin tipo',
                                                            style: const TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    primaryColorApp),
                                                          ),
                                                        ],
                                                      )),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .calendar_month_sharp,
                                                          color:
                                                              primaryColorApp,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        Text(
                                                          conteo?.dateCount !=
                                                                  null
                                                              ? DateFormat(
                                                                      'dd/MM/yyyy hh:mm ')
                                                                  .format(DateTime
                                                                      .parse(conteo!
                                                                          .dateCount
                                                                          .toString()))
                                                              : "Sin fecha",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  color: black),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Divider(
                                                    color:
                                                        grey.withOpacity(0.5),
                                                    thickness: 1,
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.add,
                                                          color:
                                                              primaryColorApp,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        const Text(
                                                          'Cantidad de lineas:',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: black),
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        Text(
                                                          conteo?.numeroLineas
                                                                  .toString() ??
                                                              '0',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  primaryColorApp),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.warehouse,
                                                          color:
                                                              primaryColorApp,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        const Text(
                                                          'Almacen:',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: black),
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        Text(
                                                          conteo?.warehouseName !=
                                                                      null &&
                                                                  conteo?.warehouseName !=
                                                                      ""
                                                              ? conteo!
                                                                  .warehouseName!
                                                              : 'Sin almacen',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  primaryColorApp),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.notes,
                                                          color:
                                                              primaryColorApp,
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        const Text(
                                                          'Observación:',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: black),
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        Flexible(
                                                          child: Text(
                                                            conteo?.observationGeneral !=
                                                                        null &&
                                                                    conteo?.observationGeneral !=
                                                                        ""
                                                                ? conteo!
                                                                    .observationGeneral!
                                                                : 'Sin observación',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    primaryColorApp),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.person,
                                                            color:
                                                                primaryColorApp,
                                                            size: 15,
                                                          ),
                                                          const SizedBox(
                                                              width: 5),
                                                          Text(
                                                            conteo?.responsableName ??
                                                                'Sin usuario',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    conteo?.responsableName !=
                                                                            null
                                                                        ? black
                                                                        : red),
                                                          ),
                                                        ],
                                                      )),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ));
                                  }))
                    ],
                  ),
                ),
              ));
        },
      ),
    );
  }
}
