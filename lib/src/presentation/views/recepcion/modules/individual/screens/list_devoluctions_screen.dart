// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/network/check_internet_connection.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/src/presentation/views/user/screens/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/user/screens/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';

class ListDevolutionsScreen extends StatefulWidget {
  const ListDevolutionsScreen({super.key});

  @override
  State<ListDevolutionsScreen> createState() => _ListDevolutionsScreenState();
}

class _ListDevolutionsScreenState extends State<ListDevolutionsScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocConsumer<RecepcionBloc, RecepcionState>(
      listener: (context, state) {
        if (state is AssignUserToOrderFailure) {
          Get.snackbar(
            '360 Software Informa',
            state.error,
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.red),
          );
        } else if (state is NeedUpdateVersionState) {
          Get.snackbar(
            '360 Software Informa',
            'Hay una nueva versión disponible. Actualiza desde la configuración de la app, pulsando el nombre de usuario en el Home',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.amber),
            showProgressIndicator: true,
            duration: Duration(seconds: 5),
          );
        } else if (state is AssignUserToOrderSuccess) {
          Get.snackbar(
            '360 Software Informa',
            "Se ha asignado el responsable correctamente",
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.green),
          );
          context
              .read<RecepcionBloc>()
              .add(GetPorductsToEntrada(state.ordenCompra.id ?? 0, 'dev'));
          context
              .read<RecepcionBloc>()
              .add(CurrentOrdenesCompra(state.ordenCompra));
          Navigator.pushReplacementNamed(
            context,
            'recepcion',
            arguments: [state.ordenCompra, 0],
          );
        } else if (state is FetchDevolucionesLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const DialogLoading(
              message: 'Cargando recepciones...',
            ),
          );
        } else if (state is FetchDevolucionesFailure) {
          Navigator.pop(context);
          showScrollableErrorDialog(state.error);
        } else if (state is FetchDevolucionesSuccess) {
          if (state.ordenesCompra.isEmpty) {
            Get.snackbar(
              '360 Software Informa',
              "No hay recepciones disponibles",
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.amber),
            );
          }
          Navigator.pop(context);
        } else if (state is DeviceNotAuthorized) {
          Navigator.pop(context);
          Get.defaultDialog(
            title: 'Dispositivo no autorizado',
            titleStyle: TextStyle(
                color: primaryColorApp,
                fontWeight: FontWeight.bold,
                fontSize: 16),
            middleText:
                'Este dispositivo no está autorizado para usar la aplicación. su suscripción ha expirado o no está activa, por favor contacte con el administrador.',
            middleTextStyle: TextStyle(color: black, fontSize: 14),
            backgroundColor: Colors.white,
            radius: 10,
            barrierDismissible:
                false, // Evita que se cierre al tocar fuera del diálogo
            onWillPop: () async => false,
          );
        }
      },
      builder: (context, state) {
        final ordenCompra = context
            .read<RecepcionBloc>()
            .listFiltersDevolutions
            .where(
                (element) => element.isFinish == 0 || element.isFinish == null)
            .toList();
        // ;
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
              backgroundColor: white,
              bottomNavigationBar: context
                      .read<RecepcionBloc>()
                      .isKeyboardVisible
                  ? CustomKeyboard(
                      isLogin: false,
                      controller:
                          context.read<RecepcionBloc>().searchControllerDev,
                      onchanged: () {
                        context.read<RecepcionBloc>().add(SearchDevolucionEvent(
                              context
                                  .read<RecepcionBloc>()
                                  .searchControllerDev
                                  .text,
                            ));
                      },
                    )
                  : null,
              body: SizedBox(
                width: size.width * 1,
                height: size.height * 1,
                child: Column(
                  children: [
                    //* appbar
                    AppBar(size: size),
                    //*barra buscar
                    DynamicSearchBar(
                      controller:
                          context.read<RecepcionBloc>().searchControllerDev,
                      hintText: "Buscar devolucion",
                      onSearchChanged: (value) {
                        context
                            .read<RecepcionBloc>()
                            .add(SearchDevolucionEvent(value));
                      },
                      onSearchCleared: () {
                        final recepcionBloc = context.read<RecepcionBloc>();
                        recepcionBloc.searchControllerDev
                            .clear(); // Limpiamos el controlador
                        recepcionBloc.add(SearchDevolucionEvent(''));
                        recepcionBloc.add(ShowKeyboardEvent(false));
                        Future.microtask(() {
                          FocusScope.of(context)
                              .unfocus(); // Desenfocamos primero
                        });
                      },
                      onTap: () {
                        context
                            .read<RecepcionBloc>()
                            .add(ShowKeyboardEvent(true));
                      },
                    ),
                    (ordenCompra.isEmpty)
                        ? Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const Text('No hay devoluciones',
                                    style:
                                        TextStyle(fontSize: 14, color: grey)),
                                const Text('Intente buscar otra devolucion',
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
                                padding: const EdgeInsets.only(top: 2),
                                itemCount: ordenCompra.length,
                                itemBuilder:
                                    (BuildContext contextList, int index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 10,
                                    ),
                                    child: Card(
                                      elevation: 3,
                                      color: ordenCompra[index]
                                                      .startTimeReception !=
                                                  "" &&
                                              ordenCompra[index]
                                                      .responsableId !=
                                                  0
                                          ? primaryColorAppLigth
                                          : ordenCompra[index].isFinish == 1
                                              ? Colors.green[200]
                                              : white,
                                      child: ListTile(
                                        trailing: Icon(Icons.arrow_forward_ios,
                                            color: primaryColorApp),
                                        title: Text(
                                            ordenCompra[index].name ?? '',
                                            style: TextStyle(
                                                color: primaryColorApp,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                        subtitle: Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Text('Tipo de entrada: ',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp)),
                                                  Text(
                                                    ordenCompra[index]
                                                            .pickingType ??
                                                        "",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
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
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp)),
                                                  Text(
                                                    ordenCompra[index]
                                                                .priority ==
                                                            '0'
                                                        ? 'Normal'
                                                        : 'Alta'
                                                            "",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: ordenCompra[index]
                                                                  .priority ==
                                                              '0'
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
                                                    ordenCompra[index]
                                                                .fechaCreacion !=
                                                            null
                                                        ? DateFormat(
                                                                'dd/MM/yyyy hh:mm ')
                                                            .format(DateTime.parse(
                                                                ordenCompra[
                                                                        index]
                                                                    .fechaCreacion!))
                                                        : "Sin fecha",
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                  ordenCompra[index]
                                                          .proveedor ??
                                                      '',
                                                  style: TextStyle(
                                                    color: black,
                                                    fontSize: 12,
                                                  )),
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
                                                  Text(
                                                    ordenCompra[index]
                                                                .purchaseOrderName ==
                                                            ""
                                                        ? 'Sin orden de compra'
                                                        : ordenCompra[index]
                                                                .purchaseOrderName ??
                                                            '',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Visibility(
                                              visible: ordenCompra[index]
                                                      .backorderId !=
                                                  0,
                                              child: Row(
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Icon(
                                                        Icons.file_copy_rounded,
                                                        color: primaryColorApp,
                                                        size: 15),
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Text(
                                                      ordenCompra[index]
                                                              .backorderName ??
                                                          '',
                                                      style: TextStyle(
                                                          color: black,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Ubicacion destino: ',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColorApp),
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                ordenCompra[index]
                                                        .locationDestName ??
                                                    '',
                                                style: const TextStyle(
                                                    fontSize: 12, color: black),
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
                                                    "Cantidad de lineas: ",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      ordenCompra[index]
                                                          .numeroLineas
                                                          .toString(),
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                                    "Cantidad unidades: ",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: black),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      ordenCompra[index]
                                                          .numeroItems
                                                          .toString(),
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              primaryColorApp),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                                  Text(
                                                    ordenCompra[index]
                                                                .responsable ==
                                                            ""
                                                        ? 'sin responsable'
                                                        : ordenCompra[index]
                                                                .responsable ??
                                                            '',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: ordenCompra[
                                                                        index]
                                                                    .responsable ==
                                                                ""
                                                            ? Colors.red
                                                            : black),
                                                  ),
                                                  const Spacer(),
                                                  ordenCompra[index]
                                                              .startTimeReception !=
                                                          ""
                                                      ? Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 5),
                                                          child:
                                                              GestureDetector(
                                                            onTap: () {
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) =>
                                                                          DialogInfo(
                                                                            title:
                                                                                'Tiempo de inicio de operacion',
                                                                            body:
                                                                                'Este orden fue iniciada a las ${ordenCompra[index].startTimeReception}',
                                                                          ));
                                                            },
                                                            child: Icon(
                                                              Icons.timer_sharp,
                                                              color: black,
                                                              size: 15,
                                                            ),
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () async {
                                          print(
                                              'ordenCompra: ${ordenCompra[index].toMap()}');
                                          //cargamos los permisos del usuario
                                          context.read<RecepcionBloc>().add(
                                              LoadConfigurationsUserOrder());

                                          //verficamos is la orden de entrada tiene ya un responsable
                                          if (ordenCompra[index]
                                                      .responsableId ==
                                                  null ||
                                              ordenCompra[index]
                                                      .responsableId ==
                                                  0) {
                                            showDialog(
                                              context: context,
                                              barrierDismissible:
                                                  false, // No permitir que el usuario cierre el diálogo manualmente
                                              builder: (context) =>
                                                  DialogAsignUserToOrderWidget(
                                                title:
                                                    'Esta seguro de tomar esta orden, una vez aceptada no podrá ser cancelada desde la app, una vez asignada se registrará el tiempo de inicio de la operación.',
                                                onAccepted: () async {
                                                  context
                                                      .read<RecepcionBloc>()
                                                      .searchControllerDev
                                                      .clear();

                                                  context
                                                      .read<RecepcionBloc>()
                                                      .add(
                                                          SearchDevolucionEvent(
                                                        '',
                                                      ));

                                                  context
                                                      .read<RecepcionBloc>()
                                                      .add(ShowKeyboardEvent(
                                                          false));

                                                  //asignamos el responsable a esa orden de entrada
                                                  context
                                                      .read<RecepcionBloc>()
                                                      .add(AssignUserToOrder(
                                                        ordenCompra[index],
                                                      ));
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            );
                                          } else {
                                            validateTime(
                                                ordenCompra[index], context);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                }),
                          )
                  ],
                ),
              )),
        );
      },
    );
  }

  void validateTime(ResultEntrada ordenCompra, BuildContext context) {
    final recepcionBloc = context.read<RecepcionBloc>();

    if (ordenCompra.startTimeReception == "" ||
        ordenCompra.startTimeReception == null) {
      showDialog(
        context: context,
        barrierDismissible:
            false, // No permitir que el usuario cierre el diálogo manualmente
        builder: (dialogContext) => DialogStartTimeWidget(
          onAccepted: () async {
            recepcionBloc.searchControllerDev.clear();
            recepcionBloc.add(SearchDevolucionEvent(''));
            recepcionBloc.add(ShowKeyboardEvent(false));
            recepcionBloc.add(StartOrStopTimeOrder(
                ordenCompra.id ?? 0, "start_time_reception"));
            recepcionBloc.add(GetPorductsToEntrada(ordenCompra.id ?? 0, 'dev'));
            recepcionBloc.add(CurrentOrdenesCompra(ordenCompra));
            Navigator.pop(dialogContext);
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                'recepcion',
                arguments: [ordenCompra, 0],
              );
            }
          },
          title: 'Iniciar Recepcion',
        ),
      );
    } else {
      recepcionBloc.searchControllerDev.clear();
      recepcionBloc.add(SearchDevolucionEvent(''));
      recepcionBloc.add(ShowKeyboardEvent(false));
      recepcionBloc.add(GetPorductsToEntrada(ordenCompra.id ?? 0, 'dev'));
      //traemos la orden de entrada actual desde la bd actualizada
      recepcionBloc.add(CurrentOrdenesCompra(ordenCompra));
      Navigator.pushReplacementNamed(
        context,
        'recepcion',
        arguments: [ordenCompra, 0],
      );
    }
  }
}

class AppBar extends StatelessWidget {
  const AppBar({
    super.key,
    required this.size,
  });

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  bottom: 0, top: status != ConnectionStatus.online ? 0 : 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: white),
                    onPressed: () {
                      context.read<RecepcionBloc>().searchControllerDev.clear();

                      context.read<RecepcionBloc>().add(SearchDevolucionEvent(
                            '',
                          ));

                      context
                          .read<RecepcionBloc>()
                          .add(ShowKeyboardEvent(false));

                      Navigator.pushReplacementNamed(
                        context,
                        '/home',
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: size.width * 0.17),
                    child: GestureDetector(
                      onTap: () async {
                        context
                            .read<RecepcionBloc>()
                            .searchControllerDev
                            .clear();

                        context.read<RecepcionBloc>().add(SearchDevolucionEvent(
                              '',
                            ));

                        context
                            .read<RecepcionBloc>()
                            .add(ShowKeyboardEvent(false));

                        await DataBaseSqlite().deleRecepcion('dev');
                        context
                            .read<RecepcionBloc>()
                            .add(FetchDevoluciones(false));
                      },
                      child: Row(
                        children: [
                          const Text("DEVOLUCIONES",
                              style: TextStyle(color: white, fontSize: 18)),

                          ///icono de refresh
                          const SizedBox(width: 5),
                          Icon(
                            Icons.refresh,
                            color: white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Visibility(
                    visible:
                        context.read<RecepcionBloc>().tiposRecepcion.length > 1,
                    child: PopupMenuButton<String>(
                      color: white,
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                      onSelected: (value) {
                        context.read<RecepcionBloc>().add(
                              FilterReceptionByTypeEvent(value),
                            );
                      },
                      itemBuilder: (BuildContext context) {
                        // Lista fija de tipos de transferencia que ya tienes
                        final tipos = [
                          ...context.read<RecepcionBloc>().tiposRecepcion,
                          'todas'
                        ];

                        return tipos.map((tipo) {
                          final isTodas = tipo.toLowerCase() == 'todas';

                          return PopupMenuItem<String>(
                            value: tipo,
                            child: Row(
                              children: [
                                Icon(
                                  isTodas
                                      ? Icons.select_all
                                      : Icons.file_upload_outlined,
                                  color:
                                      isTodas ? Colors.grey : primaryColorApp,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isTodas ? 'Todas' : tipo,
                                  style: const TextStyle(
                                      color: black, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
