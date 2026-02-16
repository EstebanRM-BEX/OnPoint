import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/bloc/recepcion_batch_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class ListRecepctionBatchScreen extends StatelessWidget {
  const ListRecepctionBatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<RecepcionBatchBloc, RecepcionBatchState>(
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
                .read<RecepcionBatchBloc>()
                .add(GetPorductsToEntradaBatch(state.ordenCompra.id ?? 0));
            context
                .read<RecepcionBatchBloc>()
                .add(CurrentOrdenesCompraBatch(state.ordenCompra));
            Navigator.pushReplacementNamed(
              context,
              'recepcion-batch',
              arguments: [state.ordenCompra, 0],
            );
          } else if (state is FetchRecepcionBatchLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const DialogLoading(
                message: 'Cargando recepciones...',
              ),
            );
          } else if (state is FetchRecepcionBatchFailure) {
            Navigator.pop(context);
            showScrollableErrorDialog(state.error);
          } else if (state is FetchRecepcionBatchSuccessFromBD) {
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
          final bloc = context.read<RecepcionBatchBloc>();

          final recepcionBatch = bloc.listReceptionBatchFilter
              .where((element) =>
                  element.isFinish == 0 || element.isFinish == null)
              .toList();
          return Scaffold(
              backgroundColor: white,
              body: SizedBox(
                width: size.width * 1,
                height: size.height * 1,
                child: Column(
                  children: [
                    //* appbar
                    AppBar(size: size),

                    //*barra buscar
                    DynamicSearchBar(
                      controller: context
                          .read<RecepcionBatchBloc>()
                          .searchControllerRecepcionBatch,
                      hintText: "Buscar devolución por batch",
                      onSearchChanged: (value) {
                        context
                            .read<RecepcionBatchBloc>()
                            .add(SearchReceptionEvent(value));
                      },
                      onSearchCleared: () {
                        final recepcionBloc =
                            context.read<RecepcionBatchBloc>();
                        recepcionBloc.add(SearchReceptionEvent(''));
                        recepcionBloc.add(ShowKeyboardEvent(false));
                      },
                      onTap: () {
                        context
                            .read<RecepcionBatchBloc>()
                            .add(ShowKeyboardEvent(true));
                      },
                    ),
                    (recepcionBatch.isEmpty)
                        ? Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const Text('No hay recepciones',
                                    style:
                                        TextStyle(fontSize: 14, color: grey)),
                                const Text('Intente buscar otra recepcion',
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
                                itemCount: recepcionBatch.length,
                                itemBuilder:
                                    (BuildContext contextList, int index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 10,
                                    ),
                                    child: Card(
                                      elevation: 3,
                                      color: recepcionBatch[index]
                                                  .startTimeReception !=
                                              ""
                                          ? primaryColorAppLigth
                                          : recepcionBatch[index].isFinish == 1
                                              ? Colors.green[200]
                                              : white,
                                      child: ListTile(
                                        trailing: Icon(Icons.arrow_forward_ios,
                                            color: primaryColorApp),
                                        title: Text(
                                            recepcionBatch[index].name ?? '',
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
                                                    recepcionBatch[index]
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
                                                    recepcionBatch[index]
                                                                .priority ==
                                                            '0'
                                                        ? 'Normal'
                                                        : 'Alta'
                                                            "",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: recepcionBatch[
                                                                      index]
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
                                                    recepcionBatch[index]
                                                                .fechaCreacion !=
                                                            null
                                                        ? DateFormat(
                                                                'dd/MM/yyyy hh:mm ')
                                                            .format(DateTime.parse(
                                                                recepcionBatch[
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
                                                  recepcionBatch[index]
                                                          .proveedor ??
                                                      '',
                                                  style: TextStyle(
                                                    color: black,
                                                    fontSize: 12,
                                                  )),
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
                                                recepcionBatch[index]
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
                                                    Icons.person,
                                                    color: primaryColorApp,
                                                    size: 15,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    recepcionBatch[index]
                                                                .responsable ==
                                                            ""
                                                        ? 'sin responsable'
                                                        : recepcionBatch[index]
                                                                .responsable ??
                                                            '',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: recepcionBatch[
                                                                        index]
                                                                    .responsable ==
                                                                ""
                                                            ? Colors.red
                                                            : black),
                                                  ),
                                                  const Spacer(),
                                                  recepcionBatch[index]
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
                                                                                'Este orden fue iniciada a las ${recepcionBatch[index].startTimeReception}',
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
                                          bloc.add(
                                              LoadConfigurationsUserReception());

                                          print(
                                              'ordenCompra: ${recepcionBatch[index].toMap()}');
                                          //validamos si tiene responsable

                                          if (recepcionBatch[index]
                                                      .responsableId ==
                                                  0 ||
                                              recepcionBatch[index]
                                                      .responsableId ==
                                                  null) {
                                            //no tiene responsable
                                            showDialog(
                                              context: context,
                                              barrierDismissible:
                                                  false, // No permitir que el usuario cierre el diálogo manualmente
                                              builder: (context) =>
                                                  DialogAsignUserToOrderWidget(
                                                title:
                                                    'Esta seguro de tomar esta recepcion por batch, una vez aceptada no podrá ser cancelada desde la app, una vez asignada se registrará el tiempo de inicio de la operación.',
                                                onAccepted: () async {
                                                  bloc.searchControllerRecepcionBatch
                                                      .clear();

                                                  bloc.add(SearchReceptionEvent(
                                                    '',
                                                  ));

                                                  bloc.add(
                                                      ShowKeyboardEvent(false));

                                                  //asignamos el responsable a esa orden de entrada
                                                  bloc.add(
                                                      AssignUserToReception(
                                                    recepcionBatch[index],
                                                  ));
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            );
                                          } else {
                                            //tiene ya un responsable
                                            bloc.add(GetPorductsToEntradaBatch(
                                                recepcionBatch[index].id ?? 0));
                                            bloc.add(CurrentOrdenesCompraBatch(
                                              recepcionBatch[index],
                                            ));

                                            Navigator.pushReplacementNamed(
                                              context,
                                              'recepcion-batch',
                                              arguments: [
                                                recepcionBatch[index],
                                                0
                                              ],
                                            );
                                          }

                                          //cargamos los permisos del usuario
                                        },
                                      ),
                                    ),
                                  );
                                }),
                          )
                  ],
                ),
              ));
        },
      ),
    );
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
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: white),
                    onPressed: () {
                      context
                          .read<RecepcionBatchBloc>()
                          .searchControllerRecepcionBatch
                          .clear();

                      context
                          .read<RecepcionBatchBloc>()
                          .add(SearchReceptionEvent(
                            '',
                          ));

                      context
                          .read<RecepcionBatchBloc>()
                          .add(ShowKeyboardEvent(false));

                      Navigator.pushReplacementNamed(
                        context,
                        '/home',
                      );
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: size.width * 0.1),
                    child: GestureDetector(
                      onTap: () async {
                        context
                            .read<RecepcionBatchBloc>()
                            .searchControllerRecepcionBatch
                            .clear();

                        context
                            .read<RecepcionBatchBloc>()
                            .add(SearchReceptionEvent(
                              '',
                            ));

                        context
                            .read<RecepcionBatchBloc>()
                            .add(ShowKeyboardEvent(false));

                        // await DataBaseSqlite().deleRecepcion();
                        context.read<RecepcionBatchBloc>().add(
                            FetchRecepcionBatchEvent(isLoadinDialog: false));
                      },
                      child: Row(
                        children: [
                          const Text("DEVOLUCIONES BATCH",
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
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
