// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/response_transferencias.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/bloc/transferencia_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class ListEntradaProductsScreen extends StatefulWidget {
  const ListEntradaProductsScreen({
    super.key,
  });

  @override
  State<ListEntradaProductsScreen> createState() =>
      _ListTransferenciasScreenState();
}

class _ListTransferenciasScreenState extends State<ListEntradaProductsScreen> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    return WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: BlocConsumer<TransferenciaBloc, TransferenciaState>(
            listener: (context, state) {
          if (state is EntregaLoading) {
            context.read<TransferenciaBloc>().add(LoadLocations());
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const DialogLoading(
                message: 'Cargando transferencias...',
              ),
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
          } else if (state is EntregaError) {
            Navigator.pop(context);
            showScrollableErrorDialog(state.message);
          } else if (state is EntregaLoaded) {
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
          } else if (state is AssignUserToTransferFailure) {
            Get.snackbar(
              '360 Software Informa',
              "Error al asignar el responsable a la transferencia",
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.red),
            );
          } else if (state is AssignUserToTransferSuccess) {
            Get.snackbar(
              '360 Software Informa',
              "Se ha asignado el responsable correctamente",
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.green),
            );
            // obtenemos los productos de esa entrada
            context
                .read<TransferenciaBloc>()
                .add(GetPorductsToTransfer(state.transfer.id ?? 0));

            context
                .read<TransferenciaBloc>()
                .add(CurrentTransferencia(state.transfer));

            Navigator.pushReplacementNamed(
              context,
              'transferencia-detail',
              arguments: [state.transfer, 0],
            );
          }
        }, builder: (context, state) {
          final transferBloc = context.read<TransferenciaBloc>();

          return Scaffold(
            backgroundColor: white,
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: Column(
                children: [
                  //* appbar
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
                                top:
                                    status != ConnectionStatus.online ? 0 : 25),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: white),
                                  onPressed: () {
                                    context
                                        .read<TransferenciaBloc>()
                                        .searchControllerTransfer
                                        .clear();

                                    context
                                        .read<TransferenciaBloc>()
                                        .add(SearchTransferEvent(
                                          "",
                                          "entrega",
                                        ));

                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/home',
                                    );
                                  },
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.only(left: size.width * 0.1),
                                  child: GestureDetector(
                                    onTap: () async {
                                      await DataBaseSqlite()
                                          .deleTrasnferencia('entrega');
                                      context
                                          .read<TransferenciaBloc>()
                                          .add(FetchAllEntrega(false));
                                    },
                                    child: Row(
                                      children: [
                                        const Text("ENTREGA PRODUCTOS",
                                            style: TextStyle(
                                                color: white, fontSize: 18)),
                                        //icono de refrescar
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
                                  visible: context
                                          .read<TransferenciaBloc>()
                                          .tiposTransferencia
                                          .length >
                                      1,
                                  child: PopupMenuButton<String>(
                                    color: white,
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onSelected: (value) {
                                      context.read<TransferenciaBloc>().add(
                                            FilterTransferByTypeEvent(value),
                                          );
                                    },
                                    itemBuilder: (BuildContext context) {
                                      // Lista fija de tipos de transferencia que ya tienes
                                      final tipos = [
                                        ...context
                                            .read<TransferenciaBloc>()
                                            .tiposTransferencia,
                                        'todas'
                                      ];

                                      return tipos.map((tipo) {
                                        final isTodas =
                                            tipo.toLowerCase() == 'todas';

                                        return PopupMenuItem<String>(
                                          value: tipo,
                                          child: Row(
                                            children: [
                                              Icon(
                                                isTodas
                                                    ? Icons.select_all
                                                    : Icons
                                                        .file_upload_outlined,
                                                color: isTodas
                                                    ? Colors.grey
                                                    : primaryColorApp,
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
                  ),
                  //* barra de buscar
                  DynamicSearchBar(
                    controller: context
                        .read<TransferenciaBloc>()
                        .searchControllerTransfer,
                    hintText: "Buscar entrega de productos",
                    onSearchChanged: (value) {
                      context.read<TransferenciaBloc>().add(SearchTransferEvent(
                          value,
                          'entrega')); // 'entrega' es el tipo de búsqueda
                    },
                    onSearchCleared: () {
                      final transferenciaBloc =
                          context.read<TransferenciaBloc>();
                      transferenciaBloc.searchControllerTransfer.clear();
                      transferenciaBloc.add(SearchTransferEvent('', 'entrega'));

                      Future.microtask(() {
                        if (mounted) {
                          FocusScope.of(context).unfocus();
                        }
                      });
                    },
                  ),
                  (transferBloc.entregaProductosBDFilters
                          .where((element) =>
                              element.isFinish == 0 || element.isFinish == null)
                          .toList()
                          .isEmpty)
                      ? Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Text('No hay transferencias',
                                  style: TextStyle(fontSize: 14, color: grey)),
                              const Text('Intente buscar otra transferencia',
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
                              itemCount: transferBloc.entregaProductosBDFilters
                                  .where((element) =>
                                      element.isFinish == 0 ||
                                      element.isFinish == null)
                                  .toList()
                                  .length,
                              itemBuilder: (context, index) {
                                final transferenciaDetail = transferBloc
                                    .entregaProductosBDFilters
                                    .where((element) =>
                                        element.isFinish == 0 ||
                                        element.isFinish == null)
                                    .toList()[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10, right: 10, top: 5),
                                  child: Card(
                                    elevation: 3,
                                    color:
                                        transferenciaDetail.startTimeTransfer !=
                                                ""
                                            ? primaryColorAppLigth
                                            : transferenciaDetail.isFinish == 1
                                                ? Colors.green[200]
                                                : white,
                                    child: ListTile(
                                      trailing: Icon(Icons.arrow_forward_ios,
                                          color: primaryColorApp),
                                      title: Text(
                                        '${transferenciaDetail.name}',
                                        style: TextStyle(
                                            color: primaryColorApp,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        children: [
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Tipo : ',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp),
                                                ),
                                                Text(
                                                  transferenciaDetail
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
                                                  transferenciaDetail
                                                              .priority ==
                                                          '0'
                                                      ? 'Normal'
                                                      : 'Alta'
                                                          "",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: transferenciaDetail
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
                                                  transferenciaDetail
                                                              .fechaCreacion !=
                                                          null
                                                      ? DateFormat(
                                                              'dd/MM/yyyy hh:mm ')
                                                          .format(DateTime.parse(
                                                              transferenciaDetail
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
                                                transferenciaDetail.proveedor ==
                                                        ""
                                                    ? 'Sin proveedor'
                                                    : transferenciaDetail
                                                            .proveedor ??
                                                        '',
                                                style: TextStyle(
                                                  color: transferenciaDetail
                                                              .proveedor ==
                                                          ""
                                                      ? red
                                                      : black,
                                                  fontSize: 12,
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
                                                Text(
                                                  transferenciaDetail.origin ==
                                                          ""
                                                      ? 'Sin orden de compra'
                                                      : transferenciaDetail
                                                              .origin ??
                                                          '',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: black),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                            visible: transferenciaDetail
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
                                                    transferenciaDetail
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
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  color: primaryColorApp,
                                                  size: 15,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  transferenciaDetail
                                                              .responsable ==
                                                          ""
                                                      ? 'sin responsable'
                                                      : transferenciaDetail
                                                              .responsable ??
                                                          '',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: transferenciaDetail
                                                                  .responsable ==
                                                              ""
                                                          ? Colors.red
                                                          : black),
                                                ),
                                                const Spacer(),
                                                transferenciaDetail
                                                            .startTimeTransfer !=
                                                        ""
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 5),
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (context) =>
                                                                      DialogInfo(
                                                                title:
                                                                    'Tiempo de inicio de operacion',
                                                                body:
                                                                    'Este orden fue iniciada a las ${transferenciaDetail.startTimeTransfer}',
                                                              ),
                                                            );
                                                          },
                                                          child: Icon(
                                                            Icons.timer_sharp,
                                                            color:
                                                                primaryColorApp,
                                                            size: 15,
                                                          ),
                                                        ),
                                                      )
                                                    : const SizedBox(),
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
                                              transferenciaDetail
                                                      .locationDestName ??
                                                  'Sin ubicacion',
                                              style: const TextStyle(
                                                  fontSize: 12, color: black),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        print(
                                            'transferenciaDetail: ${transferenciaDetail.toMap()}');
                                        //cargamos los permisos del usuario
                                        context.read<TransferenciaBloc>().add(
                                            LoadConfigurationsUserTransfer());

                                        //verificamos si la orden de entrada tiene ya un responsable
                                        if (transferenciaDetail.responsableId ==
                                                null ||
                                            transferenciaDetail.responsableId ==
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
                                                    .read<TransferenciaBloc>()
                                                    .searchControllerTransfer
                                                    .clear();

                                                context
                                                    .read<TransferenciaBloc>()
                                                    .add(SearchTransferEvent(
                                                      "",
                                                      'entrega',
                                                    ));
                                                //asignamos el responsable a esa orden de entrada
                                                context
                                                    .read<TransferenciaBloc>()
                                                    .add(
                                                      AssignUserToTransfer(
                                                          transferenciaDetail),
                                                    );
                                                Navigator.pop(context);
                                              },
                                            ),
                                          );
                                        } else {
                                          validateTime(
                                              transferenciaDetail, context);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              })),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        }));
  }

  void validateTime(ResultTransFerencias transfer, BuildContext context) {
    final transferenciaBloc = context.read<TransferenciaBloc>();

    if (transfer.startTimeTransfer == "" ||
        transfer.startTimeTransfer == null) {
      showDialog(
        context: context,
        barrierDismissible:
            false, // No permitir que el usuario cierre el diálogo manualmente
        builder: (dialogContext) => DialogStartTimeWidget(
          onAccepted: () async {
            transferenciaBloc.searchControllerTransfer.clear();
            transferenciaBloc.add(SearchTransferEvent("", 'entrega'));
            transferenciaBloc.add(StartOrStopTimeTransfer(
              transfer.id ?? 0,
              "start_time_transfer",
            ));
            transferenciaBloc.add(GetPorductsToTransfer(transfer.id ?? 0));
            transferenciaBloc.add(CurrentTransferencia(transfer));
            Navigator.pop(dialogContext);
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                'transferencia-detail',
                arguments: [transfer, 0],
              );
            }
          },
          title: 'Iniciar Transferencia',
        ),
      );
    } else {
      transferenciaBloc.searchControllerTransfer.clear();
      transferenciaBloc.add(SearchTransferEvent("", 'entrega'));
      transferenciaBloc.add(GetPorductsToTransfer(transfer.id ?? 0));
      transferenciaBloc.add(CurrentTransferencia(transfer));
      transferenciaBloc.add(LoadLocations());
      Navigator.pushReplacementNamed(
        context,
        'transferencia-detail',
        arguments: [transfer, 0],
      );
    }
  }
}
