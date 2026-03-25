import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
// ignore_for_file: must_be_immutable, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_holo_date_picker/date_picker.dart';
import 'package:flutter_holo_date_picker/i18n/date_picker_i18n.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/models/response_pick_model.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class IndexListPickComponentsScreen extends StatelessWidget {
  IndexListPickComponentsScreen({super.key});

  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  FocusNode focusNodeBuscar = FocusNode();
  final TextEditingController _controllerToDo = TextEditingController();

  void validateBarcode(String value, BuildContext context) {
    final bloc = context.read<PickingPickBloc>();
    final scan = value.trim().toLowerCase();

    _controllerToDo.clear();
    debugPrint('🔎 Scan barcode (batch picking): $scan');

    final listOfBatchs = bloc.listOfPickCompo;

    void processBatch(ResultPick batch) {
      try {
        _handlePickTap(context, batch, context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar los datos'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

    // Buscar el producto usando el código de barras principal o el código de producto
    final batchs = listOfBatchs.firstWhere(
      (b) =>
          b.name?.toLowerCase() == scan ||
          (b.origin?.toLowerCase() ?? '') == scan,
      orElse: () => ResultPick(),
    );

    if (batchs.id != null) {
      debugPrint('🔎 batch encontrado : ${batchs.id} ${batchs.name} ');
      processBatch(batchs);
      Future.microtask(() => focusNodeBuscar.requestFocus());
      return;
    } else {
      _audioService.playErrorSound();
      _vibrationService.vibrate();
      Future.microtask(() => focusNodeBuscar.requestFocus());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocConsumer<PickingPickBloc, PickingPickState>(
        listener: (context, state) {
          if (state is AssignUserToPickError) {
            Get.snackbar(
              '360 Software Informa',
              state.error,
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.red),
            );
          }

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

          if (state is AssignUserToPickLoading) {
            // mostramos un dialogo de carga y despues
            showDialog(
              context: context,
              barrierDismissible:
                  false, // No permitir que el usuario cierre el diálogo manualmente
              builder: (_) => const DialogLoading(
                message: 'Cargando interfaz...',
              ),
            );
          }

          if (state is AssignUserToPickSuccess) {
            // cerramos el dialogo de carga
            Navigator.pop(context);
            context
                .read<PickingPickBloc>()
                .add(FetchPickWithProductsEvent(state.id));
            context.read<PickingPickBloc>().add(LoadAllNovedadesPickEvent());
            context.read<PickingPickBloc>().add(LoadConfigurationsUser());
            Navigator.pushReplacementNamed(context, 'scan-product-pick');
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: primaryColorApp,
            body: SafeArea(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      //*appbar
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColorApp,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: BlocBuilder<ConnectionStatusCubit,
                            ConnectionStatus>(builder: (context, status) {
                          return Column(
                            children: [
                              const WarningWidgetCubit(),
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 10, right: 10, bottom: 0),
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
                                            context
                                                .read<PickingPickBloc>()
                                                .searchPickController
                                                .clear();
                                            Navigator.pushReplacementNamed(
                                                context, '/home');
                                          },
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final bloc =
                                                context.read<PickingPickBloc>();
                                            if (bloc.state
                                                    is PickingPickCompoLoading ||
                                                bloc.state
                                                    is PickingPickCompoBDLoading) {
                                              return;
                                            }
                                            await DataBaseSqlite()
                                                .delePick('pick-componentes');
                                            bloc.add(
                                                FetchPickingComponentesEvent(
                                                    true));
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                left: size.width * 0.05),
                                            child: Row(
                                              children: [
                                                const Text(
                                                  'PICKING COMPONENTES',
                                                  style: TextStyle(
                                                      color: white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),

                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                //icono de refres
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
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      //*barra de buscar
                      Row(
                        children: [
                          DynamicSearchBar(
                            width: size.width * 0.8,
                            controller: context
                                .read<PickingPickBloc>()
                                .searchPickController,
                            hintText: "Buscar pick",
                            onSearchChanged: (value) {
                              context
                                  .read<PickingPickBloc>()
                                  .add(SearchPickEvent(value, true));
                            },
                            onSearchCleared: () {
                              context
                                  .read<PickingPickBloc>()
                                  .searchPickController
                                  .clear();
                              context
                                  .read<PickingPickBloc>()
                                  .add(SearchPickEvent('', true));
                              Future.microtask(() {
                                FocusScope.of(context)
                                    .requestFocus(focusNodeBuscar);
                              });
                            },
                          ),

                          //icono de fecha
                          GestureDetector(
                            onTap: () async {
                              // Primero, asegúrate de que el FocusNode esté activo
                              FocusScope.of(context).unfocus();
                              var pickedDate =
                                  await DatePicker.showSimpleDatePicker(
                                titleText: 'Seleccione una fecha',
                                context,
                                confirmText: 'Buscar',
                                cancelText: 'Cancelar',
                                // initialDate: DateTime(2020),
                                firstDate:
                                    //un mes atras
                                    DateTime.now()
                                        .subtract(const Duration(days: 30)),
                                lastDate: DateTime.now(),
                                dateFormat: "dd-MMMM-yyyy",
                                locale: DateTimePickerLocale.es,
                                looping: false,
                              );

                              // Verificar si el usuario seleccionó una fecha
                              if (pickedDate != null) {
                                // Formatear la fecha al formato "yyyy-MM-dd"
                                final formattedDate =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);

                                // Disparar el evento con la fecha seleccionada
                                context.read<PickingPickBloc>().add(
                                      LoadHistoryPickComponentEvent(
                                          true, formattedDate),
                                    );

                                // Navegar a la pantalla de historial
                                Navigator.pushReplacementNamed(
                                    context, 'pick-done',
                                    arguments: [false]);
                              }
                            },
                            child: Card(
                              elevation: 3,
                              color: white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.calendar_month,
                                  color: primaryColorApp,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),

                      //*buscar por scan
                      BarcodeScannerField(
                        controller: _controllerToDo,
                        focusNode: focusNodeBuscar,
                        onBarcodeScanned: (value, context) {
                          return validateBarcode(value, context);
                        },
                      ),

                      Expanded(
                        child: context
                                .read<PickingPickBloc>()
                                .listOfPickCompoFiltered
                                .where((batch) => batch.isSeparate == 0)
                                .isNotEmpty
                            ? ListView.builder(
                                padding: EdgeInsets.only(
                                    top: 10, bottom: size.height * 0.15),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: context
                                    .read<PickingPickBloc>()
                                    .listOfPickCompoFiltered
                                    .where((batch) => batch.isSeparate == 0)
                                    .length,
                                itemBuilder: (contextBuilder, index) {
                                  final batch = context
                                      .read<PickingPickBloc>()
                                      .listOfPickCompoFiltered
                                      .where((batch) => batch.isSeparate == 0)
                                      .toList()[index];
                                  //convertimos la fecha

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        _handlePickTap(
                                            context, batch, contextBuilder);
                                      },
                                      child: Card(
                                        color: batch.isSeparate == 1
                                            ? Colors.green[100]
                                            : batch.isSelected == 1
                                                ? primaryColorAppLigth
                                                : Colors.white,
                                        elevation: 3,
                                        child: ListTile(
                                          trailing: Icon(
                                            Icons.arrow_forward_ios,
                                            color: primaryColorApp,
                                          ),
                                          leading: Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),

                                                //sombras
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 5,
                                                      offset: Offset(0, 2))
                                                ]),
                                            child: Image.asset(
                                              "assets/icons/producto.png",
                                              color: primaryColorApp,
                                              width: 24,
                                            ),
                                          ),
                                          title: Text(batch.name ?? '',
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                          subtitle: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                        "Tipo de operación:",
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: grey)),
                                                  ),
                                                  const Spacer(),
                                                  batch.startTimeTransfer != ""
                                                      ? GestureDetector(
                                                          onTap: () {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        DialogInfo(
                                                                          title:
                                                                              'Tiempo de inicio',
                                                                          body:
                                                                              'Este Pick fue iniciado a las ${batch.startTimeTransfer}',
                                                                        ));
                                                          },
                                                          child: Icon(
                                                            Icons.timer_sharp,
                                                            color:
                                                                primaryColorApp,
                                                            size: 15,
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                ],
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
                                                      batch.priority == '0'
                                                          ? 'Normal'
                                                          : 'Alta'
                                                              "",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: batch.priority ==
                                                                '0'
                                                            ? black
                                                            : red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text('Producto: ',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp)),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      batch.productoFinalNombre ==
                                                              ''
                                                          ? 'Sin nombre'
                                                          : batch.productoFinalNombre ??
                                                              '',
                                                      maxLines: 2,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            batch.productoFinalNombre ==
                                                                    ''
                                                                ? red
                                                                : black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Text('Referencia: ',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp)),
                                                    Text(
                                                      batch.productoFinalReferencia ==
                                                              ''
                                                          ? 'Sin referencia'
                                                          : batch.productoFinalReferencia ??
                                                              '',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            batch.productoFinalReferencia ==
                                                                    ''
                                                                ? red
                                                                : black,
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
                                                child: Text(
                                                  batch.pickingType.toString(),
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: primaryColorApp),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .calendar_month_sharp,
                                                      color: primaryColorApp,
                                                      size: 15,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      batch.fechaCreacion !=
                                                              null
                                                          ? DateFormat(
                                                                  'dd/MM/yyyy')
                                                              .format(DateTime
                                                                  .parse(batch
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
                                                        batch.responsable == ""
                                                            ? "Sin responsable"
                                                            : batch.responsable ??
                                                                '',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                batch.responsable ==
                                                                        ""
                                                                    ? red
                                                                    : black),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Visibility(
                                                visible: batch.backorderId != 0,
                                                child: Row(
                                                  children: [
                                                    Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Icon(
                                                          Icons
                                                              .shopping_cart_rounded,
                                                          color:
                                                              primaryColorApp,
                                                          size: 15),
                                                    ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    Text(
                                                        batch.backorderName ??
                                                            '',
                                                        style: TextStyle(
                                                            color: black,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
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
                                                        batch.proveedor == ""
                                                            ? "Sin contacto"
                                                            : batch.proveedor ??
                                                                '',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                batch.proveedor ==
                                                                        ""
                                                                    ? red
                                                                    : black),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                                      Icons.file_copy_rounded,
                                                      color: primaryColorApp,
                                                      size: 15,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    const Text(
                                                      "Doc. Origen: ",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: black),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        batch.origin.toString(),
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                                        batch.numeroLineas
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                                        batch.numeroItems
                                                            .toString(),
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                primaryColorApp),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 10),
                                    Text('No se encontraron resultados',
                                        style: TextStyle(
                                            fontSize: 18, color: grey)),
                                    Text('Intenta con otra búsqueda',
                                        style: TextStyle(
                                            fontSize: 14, color: grey)),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handlePickTap(
      BuildContext context, dynamic batch, BuildContext contextBuilder) async {
    debugPrint("Batch: ${batch.toMap()}");
    final bloc = context
        .read<PickingPickBloc>(); // Asegúrate que el BLoC sea el correcto

    context.read<PickingPickBloc>().add(LoadConfigurationsUser());

    try {
      // Lógica para asignar responsable si no existe
      if (batch.responsableId == null || batch.responsableId == 0) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DialogAsignUserWidget(
            title:
                'Esta seguro de tomar este pick, una vez aceptado no podrá ser cancelada desde la app, una vez asignada se registrará el tiempo de inicio de la operación.',
            onCancel: () {
              Future.microtask(() => focusNodeBuscar.requestFocus());
              Navigator.pop(dialogContext);
              return;
            },
            onAccepted: () async {
              bloc.searchPickController.clear();
              bloc.add(SearchPickEvent('', true));
              bloc.add(AssignUserToTransfer(batch.id ?? 0));
              Navigator.pop(dialogContext); // Cierra el diálogo de asignación
            },
          ),
        );
      } else {
        validateTime(batch, context);
      }
    } catch (e) {
      // Manejo de errores centralizado
      ScaffoldMessenger.of(contextBuilder).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar los datos'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void validateTime(dynamic batch, BuildContext context) {
    final bloc = context.read<PickingPickBloc>();

    if (batch.startTimeTransfer == "" || batch.startTimeTransfer == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => DialogStartTimeWidget(
          title: 'Iniciar Pick',
          onAccepted: () async {
            bloc.searchPickController.clear();
            bloc.add(SearchPickEvent('', true));
            bloc.add(
                StartOrStopTimeTransfer(batch.id ?? 0, 'start_time_transfer'));
            bloc.add(FetchPickWithProductsEvent(batch.id ?? 0));
            bloc.add(LoadAllNovedadesPickEvent());
            bloc.add(LoadConfigurationsUser());
            Navigator.pop(dialogContext); // Cierra el diálogo de inicio
            Navigator.pushReplacementNamed(context, 'scan-product-pick');
          },
        ),
      );
    } else {
      // Acciones comunes que se ejecutan después de los diálogos
      bloc.searchPickController.clear();
      bloc.add(SearchPickEvent('', true));
      bloc.add(FetchPickWithProductsEvent(batch.id ?? 0));
      bloc.add(LoadAllNovedadesPickEvent());
      bloc.add(LoadConfigurationsUser());

      // Navegación final
      goBatchInfo(context, bloc, batch);
    }
  }

  void goBatchInfo(
    BuildContext context,
    PickingPickBloc batchBloc,
    ResultPick batch,
  ) async {
    // mostramos un dialogo de carga y despues
    showDialog(
      context: context,
      barrierDismissible:
          false, // No permitir que el usuario cierre el diálogo manualmente
      builder: (_) => const DialogLoading(
        message: 'Cargando interfaz...',
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);
    // Si batch.isSeparate es 1, entonces navegamos a "batch-detail"
    if (batch.isSeparate != 1) {
      batchBloc.searchPickController.clear();
      Navigator.pushReplacementNamed(context, 'scan-product-pick');
    } else {}
  }
}
